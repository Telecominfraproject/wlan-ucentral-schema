#!/usr/bin/ucode
push(REQUIRE_SEARCH_PATH, '/usr/share/ucentral/*.uc');
let fs = require("fs");

let uci = require("uci");
let ubus = require("ubus");
let cfgfile = fs.open("/etc/ucentral/ucentral.active", "r");
let cfg = json(cfgfile.read("all"));
let capabfile = fs.open("/etc/ucentral/capabilities.json", "r");
let capab = json(capabfile.read("all"));
let vsifile = fs.open("/tmp/udhcpc-vsi.json", "r");
let vsi = vsifile ? json(vsifile.read("all")) : null;
let now = time();

/* set up basic functionality */
if (!cursor)
	cursor = uci.cursor();
if (!ctx)
	ctx = ubus.connect();

let state = {
	unit: { memory: {} },
	radios: [],
	interfaces: []
};

function discover_ports() {
	let roles = {};

	/* Derive ethernet port names and roles from default config */
	for (let role, spec in capab.network) {
		for (let i, ifname in spec) {
			role = uc(role);
			push(roles[role] = roles[role] || [], {
				netdev: ifname,
				index: i
			});
		}
	}

	/* Sort ports in each role group according to their index, then normalize
	 * names into uppercase role name with 1-based index suffix in case of multiple
	 * ports or just uppercase role name in case of single ports */
	let rv = {};

	for (let role, ports in roles) {
		switch (length(ports)) {
		case 0:
			break;

		case 1:
			rv[role] = ports[0];
			break;

		default:
			map(sort(ports, (a, b) => (a.index - b.index)), (port, i) => {
				rv[role + (i + 1)] = port;
			});
		}
	}

	return rv;
}

let select_ports = discover_ports();

function lookup_port(netdev) {
	for (let k, v in select_ports)
		if (v.netdev == netdev)
			return k;
	return 'unknown';
}

/* find out what telemetry we should gather */
let stats;
cursor.load("state");
cursor.load("event");
if (!length(stats)) {
	stats = cursor.get_all("state", "stats");
}

let delta = 1;
if (telemetry)
	delta = 0;

global.tid_stats = (index(stats.types, 'tid-stats') > 0);

/* load state data */
let ipv6leases = ctx.call("dhcp", "ipv6leases");
let topology = ctx.call("topology", "mac");
let wifistatus = ctx.call("network.wireless", "status");
let wifiphy = require('wifi.phy');
let wifiiface = require('wifi.iface');
let stations = require('wifi.station');
let survey = require('wifi.survey');
let mesh = require('wifi.mesh');
let ports = ctx.call("topology", "port", { delta });
let poe = ctx.call("poe", "info");
let gps = ctx.call("gps", "info");
let ieee8021x = ctx.call("ieee8021x", "dump");
let devstats = ctx.call('udevstats', 'dump');
let devices = ctx.call("network.device", "status");
let previous = json(fs.readfile('/tmp/' + (telemetry ? 'telemetry.json' : 'state.json')) || '{ "ports": {}, "devstats": {}, "stations": {}, "devstats": {} }');
let finger_config = cursor.get_all("state", "fingerprint");
let finger_state = json(fs.readfile('/tmp/finger.state') || '{}');
let fingerprint;
if (finger_config?.mode != 'polled')
	fingerprint = ctx.call("fingerprint", "fingerprint", { age: +(finger_config?.min_age || 0), raw: (finger_config?.mode == 'raw') }) || {};
let finger_wan = [];
if (!+finger_config?.allow_wan) 
	for (let k in cursor.get("event", "config", "wan_port"))
		push(finger_wan, lookup_port(k));
let stations_lookup = {};
for (let k, v in stations) {
	stations_lookup[k] = {};
	for (let assoc in v)
		stations_lookup[k][assoc.station] = assoc;
}

fs.writefile('/tmp/' + (telemetry ? 'telemetry.json' : 'state.json'), { ports, devstats, stations: stations_lookup, devstats });

if (fingerprint) {
	for (let mac in fingerprint) {
		if (!finger_state[mac])
			finger_state[mac] = { reported: 0 };
		finger_state[mac].seen = now;
	}

	for (let mac, data in finger_state)
		if ((now - data.seen) > (+finger_config?.max_age || 600))
			delete finger_state[mac];
}

//printf('%.J\n', previous);

let lldp = [];
let wireless = cursor.get_all("wireless");
let snoop = ctx.call("dhcpsnoop", "dump");
let captive = ctx.call("spotfilter", "client_list", { "interface": "hotspot"});

function generate_deltas(counters, prev_counters) {
	let ret = {};
 	for (let k in [ "rx_packets", "tx_packets", "rx_bytes", "tx_bytes", "tx_retries", "tx_failed", "rx_errors", "tx_errors", "rx_dropped", "tx_dropped",  "multicast", "collisions" ]) {
		if (prev_counters[k] < 0)
			prev_counters[k] = 0;
		ret[k] = counters[k] - prev_counters[k];
		if (ret[k] < 0) {
			if (counters[k] > 0)
				ret[k] = counters[k];
			else
				ret[k] = 0;
		}
	}
	return ret;
}

function ports_deltas(port) {
	if (!ports[port]?.counters || !previous.ports[port]?.counters)
		return {};

	return generate_deltas(ports[port].counters, previous.ports[port].counters);
}

function stations_deltas(assoc, iface) {
	let ret = {};
	// Search for the station in the dynamic iface
	if (assoc.dynamic_vlan)
		iface = iface + "-v" + assoc.dynamic_vlan;
	if (!previous.stations[iface] || !previous.stations[iface][assoc.station])
		return ret;
	for (let k in [ "rx_packets", "tx_packets", "rx_bytes", "tx_bytes", "tx_retries", "tx_failed" ]) {
		if (assoc["connected_time"] < previous.stations[iface][assoc.station]["connected_time"]) {
			ret[k] = assoc[k];
		} else {
			ret[k] = assoc[k] - (previous.stations[iface][assoc.station][k] || 0);
		}
		// Stil negative?
		if (ret[k] < 0 && assoc[k] > 0) {
			ret[k] = assoc[k];
		} else if (ret[k] < 0) {
			ret[k] = 0;
		}
	}
	return ret;
}

/* prepare dhcp leases cache */
let ip4leases = {};
try {
	let fd = fs.open("/tmp/dhcp.leases");
	if (fd) {
		let line;
		while (line = fd.read("line")) {
			let tokens = split(line, " ");

			if (length(tokens) < 4)
				continue;

			ip4leases[tokens[1]] = {
				assigned: tokens[0],
				mac: tokens[1],
				address: tokens[2],
				hostname: tokens[3]
			};
		}
		fd.close();
	}
}
catch(e) {
	printf("Failed to parse dhcp leases cache: %s\n%s\n", e, e.stacktrace[0].context);
}

/* prepare lldp cache */
try {
	let stdout = fs.popen("lldpcli -f json show neighbors");
	let tmp;
	if (stdout) {
		tmp = json(stdout.read("all")).lldp[0].interface;
		stdout.close();
	} else {
		printf("LLDP cli command failed: %s", fs.error());
	}

	for (let key, iface in tmp) {
		let peer = { };
		for (let host, chassis in iface.chassis) {
			if (!length(chassis.id) ||
			    !length(chassis.descr))
				continue;
			peer.mac = chassis.id[0].value;
			peer.ifname = iface.name;
			peer.description = chassis.descr[0].value;
			if (iface?.port[0]?.id[0]?.value && iface?.port[0]?.descr[0]?.value) {
				peer.port_id = iface.port[0].id[0].value;
				peer.port_descr = iface.port[0].descr[0].value;
			}
			if (length(chassis.name))
				peer.name = chassis.name[0].value;

			if (length(chassis['mgmt-ip'])) {
				let ipaddr = [];

				for (let ip in chassis["mgmt-ip"])
					push(ipaddr, ip.value);
				peer.management_ips = ipaddr;
			}

			if (length(chassis.capability)) {
				let cap = [];

				for (let c in chassis.capability) {
					if (!c.enabled)
						continue;
					push(cap, c.type);
				}
				peer.capability = cap;
			}

		}

		if (!length(peer))
			continue;

		push(lldp, peer);
	}
}
catch(e) {
	printf("Failed to parse LLDP cli output: %s\n%s\n", e, e.stacktrace[0].context);
}

/* system state */
let sysinfo = ctx.call("system", "info");
state.unit.localtime = sysinfo.localtime;
state.unit.uptime = sysinfo.uptime;
state.unit.load = sysinfo.load;
state.unit.memory.total = sysinfo.memory.total;
state.unit.memory.free = sysinfo.memory.free;
state.unit.memory.cached = sysinfo.memory.cached;
state.unit.memory.buffered = sysinfo.memory.buffered;


for (let l = 0; l < 3; l++)
	state.unit.load[l] /= 65535.0;

let thermal = fs.glob('/sys/class/thermal/thermal_zone*/temp');
if (length(thermal) > 0) {
	let temps = [];
	for (let t in thermal) {
		let file = fs.open(t, 'r');
		if (!file)
			continue;
		let temp = +file.read('all');
		if (temp > 1000)
			temp /= 1000;
		file.close();
		// skip non-connected thermal zones
		if (temp < 200)
			push(temps, temp);
	}
	if (length(temps) > 0) {
		let avg = 0;
		temps = sort(temps);
		for (let t in temps)
			avg += t;
		avg /= length(temps);
		state.unit.temperature = [ avg, temps[-1] ];
	}
}

/* cpu load */
let fs = require('fs');

function sum(arr) {
	let rv = 0;

	for (let val in arr)
		rv += +val;
	return rv;
}

function cpu_stats() {
	let proc = fs.open('/proc/stat', 'r');
	let stats;

	if (proc) {
		let line;
		stats = [];
		while (line = proc.read('line')) {
			let cols = split(replace(trim(line), '  ', ' '), ' ');
			if (!wildcard(cols[0], 'cpu*'))
				continue;
			shift(cols);
			push(stats, [ sum(cols), +cols[3] ]);
		}
		proc.close();
	}
	return stats;
}

let last;
let file = fs.open('/tmp/cpu_load', 'r');
if (file) {
	last = json(file.read('all'));
	file.close();
}

let now = cpu_stats();
if (now && last) {
	state.unit.cpu_load = []; 
	for (let i = 0; i < length(now); i++)
		//printf('CPU%s %3d\%\n', i ? i : ' ', 100 * (now[i][1] - last[i][1]) / (now[i][0] - last[i][0]));
		push(state.unit.cpu_load, 100 - (100 * (now[i][1] - last[i][1]) / (now[i][0] - last[i][0])));
}
file = fs.open('/tmp/cpu_load', 'w');
if (file) {
	file.write(now);
	file.close();
}

// mapping 5G to S1G(HaLow)
function map5GToS1G() {
	// format: 5G channel -> { s1g_channel, s1g_freq, s1g_bw }
	let mappingTable = {
		// 1MHz bandwidth
		'132': { s1g_channel: 1, s1g_freq: 902, s1g_bw: 1 },
		'136': { s1g_channel: 3, s1g_freq: 903, s1g_bw: 1 },
		'36': { s1g_channel: 5, s1g_freq: 904, s1g_bw: 1 },
		'40': { s1g_channel: 7, s1g_freq: 905, s1g_bw: 1 },
		'44': { s1g_channel: 9, s1g_freq: 906, s1g_bw: 1 },
		'48': { s1g_channel: 11, s1g_freq: 907, s1g_bw: 1 },
		'52': { s1g_channel: 13, s1g_freq: 908, s1g_bw: 1 },
		'56': { s1g_channel: 15, s1g_freq: 909, s1g_bw: 1 },
		'60': { s1g_channel: 17, s1g_freq: 910, s1g_bw: 1 },
		'64': { s1g_channel: 19, s1g_freq: 911, s1g_bw: 1 },
		'100': { s1g_channel: 21, s1g_freq: 912, s1g_bw: 1 },
		'104': { s1g_channel: 23, s1g_freq: 913, s1g_bw: 1 },
		'108': { s1g_channel: 25, s1g_freq: 914, s1g_bw: 1 },
		'112': { s1g_channel: 27, s1g_freq: 915, s1g_bw: 1 },
		'116': { s1g_channel: 29, s1g_freq: 916, s1g_bw: 1 },
		'120': { s1g_channel: 31, s1g_freq: 917, s1g_bw: 1 },
		'124': { s1g_channel: 33, s1g_freq: 918, s1g_bw: 1 },
		'128': { s1g_channel: 35, s1g_freq: 919, s1g_bw: 1 },
		'149': { s1g_channel: 37, s1g_freq: 920, s1g_bw: 1 },
		'153': { s1g_channel: 39, s1g_freq: 921, s1g_bw: 1 },
		'157': { s1g_channel: 41, s1g_freq: 922, s1g_bw: 1 },
		'161': { s1g_channel: 43, s1g_freq: 923, s1g_bw: 1 },
		'165': { s1g_channel: 45, s1g_freq: 924, s1g_bw: 1 },
		'169': { s1g_channel: 47, s1g_freq: 925, s1g_bw: 1 },
		'173': { s1g_channel: 49, s1g_freq: 926, s1g_bw: 1 },
		'177': { s1g_channel: 51, s1g_freq: 927, s1g_bw: 1 },

		// 2MHz bandwidth
		'134': { s1g_channel: 2, s1g_freq: 903, s1g_bw: 2 },
		'38': { s1g_channel: 6, s1g_freq: 905, s1g_bw: 2 },
		'46': { s1g_channel: 10, s1g_freq: 907, s1g_bw: 2 },
		'54': { s1g_channel: 14, s1g_freq: 909, s1g_bw: 2 },
		'62': { s1g_channel: 18, s1g_freq: 911, s1g_bw: 2 },
		'102': { s1g_channel: 22, s1g_freq: 913, s1g_bw: 2 },
		'110': { s1g_channel: 26, s1g_freq: 915, s1g_bw: 2 },
		'118': { s1g_channel: 30, s1g_freq: 917, s1g_bw: 2 },
		'126': { s1g_channel: 34, s1g_freq: 919, s1g_bw: 2 },
		'151': { s1g_channel: 38, s1g_freq: 921, s1g_bw: 2 },
		'159': { s1g_channel: 42, s1g_freq: 923, s1g_bw: 2 },
		'167': { s1g_channel: 46, s1g_freq: 925, s1g_bw: 2 },
		'175': { s1g_channel: 50, s1g_freq: 927, s1g_bw: 2 },

		// 4MHz bandwidth
		'42': { s1g_channel: 8, s1g_freq: 906, s1g_bw: 4 },
		'58': { s1g_channel: 16, s1g_freq: 910, s1g_bw: 4 },
		'106': { s1g_channel: 24, s1g_freq: 914, s1g_bw: 4 },
		'122': { s1g_channel: 32, s1g_freq: 918, s1g_bw: 4 },
		'155': { s1g_channel: 40, s1g_freq: 922, s1g_bw: 4 },
		'171': { s1g_channel: 48, s1g_freq: 926, s1g_bw: 4 },

		// 8MHz bandwidth
		'50': { s1g_channel: 12, s1g_freq: 908, s1g_bw: 8 },
		'114': { s1g_channel: 28, s1g_freq: 916, s1g_bw: 8 },
		'163': { s1g_channel: 44, s1g_freq: 924, s1g_bw: 8 }
	};

	return mappingTable;
}

/* wifi radios */
for (let radio, data in wifistatus) {
	if (!length(data.interfaces))
		continue;
	let vap = wifiiface[data.interfaces[0].ifname];
	if (!length(vap))
		continue;

	let radio = {};
	radio.channel = vap.channel[0];
	radio.channels = uniq(vap.channel);
	radio.frequency = uniq(vap.frequency);
	radio.channel_width = +vap.ch_width;
	radio.tx_power = vap.tx_power;

	let path = data.config.path;
	if (exists(data.config, 'radio'))
		path += ':' + uc(data.config.band);
	radio.phy = path;
	if (wifiphy[path] && wifiphy[path].temperature)
		radio.temperature = wifiphy[path].temperature;
	radio.band = wifiphy[path].band;

	// Check if this is a HaLow device
	if (index(radio.band, 'HaLow') != -1) {
		// Get mapping table
		let mapping_table = map5GToS1G();
		let orig_channels = radio.channels;
		let orig_frequency = radio.frequency;

		// Use the second channel in the list if available
		let selected_channel = null;
		let selected_channel_idx = -1;

		// Check if we have at least two channels in the list
		if (length(orig_channels) >= 2) {
			// Take the second channel
			selected_channel = '' + orig_channels[1]; // Convert to string
			selected_channel_idx = 1;
		} else {
			// Fallback to using the smallest channel if only one channel available
			for (let i = 0; i < length(orig_channels); i++) {
				let ch = '' + orig_channels[i]; // Convert to string
				if (mapping_table[ch] && (selected_channel === null || +ch < +selected_channel)) {
					selected_channel = ch;
					selected_channel_idx = i;
				}
			}
		}

		// If we found a valid channel to map
		if (selected_channel !== null && mapping_table[selected_channel]) {
			// Map to S1G
			let s1g_info = mapping_table[selected_channel];
			radio.channel = s1g_info.s1g_channel;

			// Set S1G bandwidth
			let bandwidth = s1g_info.s1g_bw;
			radio.channel_width = bandwidth;

			// Calculate lower and upper edge frequencies
			// For S1G channels, lower edge = center_freq - bandwidth/2
			let center_freq = s1g_info.s1g_freq;
			let lower_freq = center_freq - bandwidth / 2;
			let upper_freq = center_freq + bandwidth / 2;

			// Update frequencies to include both lower and upper edge
			radio.frequency = [lower_freq, upper_freq];

			// Convert all channels
			let s1g_channels = [];
			for (let i = 0; i < length(orig_channels); i++) {
				let ch = '' + orig_channels[i];
				if (mapping_table[ch]) {
					push(s1g_channels, mapping_table[ch].s1g_channel);
				}
			}
			if (length(s1g_channels)) {
				radio.channels = uniq(s1g_channels);
			}

			// Update survey frequencies to match the S1G center frequency in MHz
			let s1g_center_freq_khz = center_freq;

			// Collect survey items
			radio.survey = [];
			for (let k, v in survey.survey) {
				if (v.frequency in orig_frequency) {
					// Make a copy of the survey item and update frequency
					let survey_item = { ...v };
					survey_item.frequency = s1g_center_freq_khz;
					push(radio.survey, survey_item);
				}
			}
		}
	} else {
		// Non-HaLow device, process survey normally
		radio.survey = [];
		for (let k, v in survey.survey)
			if (v.frequency in radio.frequency)
				push(radio.survey, v);
	}
	delete radio.in_use;
	push(state.radios, radio);
}
if (!length(state.radios))
	delete state.radios;


function iface_add_counters(iface, vlan, port) {
	if (!devstats[port])
		return;
	for (let k, vid in devstats[port]) {
		if (vid.vid != vlan)
			continue;
		iface.counters.tx_bytes += vid.tx?.bytes || 0;
		iface.counters.tx_packets += vid.tx?.packets || 0;
		iface.counters.rx_bytes += vid.rx?.bytes || 0;
		iface.counters.rx_packets += vid.rx?.packets || 0;
		if (previous.devstats[port] && previous.devstats[port][k]) {
			iface.delta_counters = {};
			for (let v in [ 'tx_bytes', 'tx_packets', 'rx_bytes', 'rx_packets' ])
				iface.delta_counters[v] = +iface.counters[v] - (+previous.devstats[port][k] || 0);
		}
	}
}

function is_mesh(net, wif) {
	if (!net.batman)
		return false;
	if (wif.mode != 'mesh')
		return false;
	return true;
}

function get_fingerprint(mac, ports) {
	if (finger_config?.mode != 'final')
		return null;
	if (!fingerprint[mac])
		return null;
	if (ports)
		for (let port in finger_wan)
			if (port in ports)
				return 0;
	if ((time() - finger_state[mac].reported || 0) < (+finger_config.period || 0))
		return null;
	finger_state[mac].reported = time();
	return fingerprint[mac];
}

let idx = 0;
let dyn_vlans = {};
let dyn_vids = [];
if (devices?.up) for (let k, vlan in devices.up['bridge-vlans']) {
	if (vlan.id >= 4000)
		continue;
	let wlan = [];
	for (let port in vlan.ports) {
		let dev = split(port, '-v');
		if (+dev[1] != vlan.id)
			continue;
		if (!dyn_vlans[dev[0]])
			dyn_vlans[dev[0]] = [];
		push(dyn_vlans[dev[0]], port);
	}
}

/* interfaces */
cursor.load("network");
cursor.foreach("network", "interface", function(d) {
	let name = d[".name"];
	if (name == "loopback")
		return;
	if (index(name, "_") >= 0)
		return;
	if (!d.ucentral_path)
		return;
	let role = split(name, /[[:digit:]]/)[0];
	let vlan = split(name, 'v')[1];
	let iface_port;

	let iface = { name, location: d.ucentral_path, ipv4:{}, ipv6:{} };
	let ipv4leases = [];

	push(state.interfaces, iface);

	let status = ctx.call(sprintf("network.interface.%s", name) , "status");

	if (!length(status))
		return;

	if (devices && devices[role] && length(devices[role]["bridge-members"]))
		iface_ports = devices[role]["bridge-members"];
	iface.uptime = status.uptime || 0;

	if (length(status["ipv4-address"])) {
		let ipv4 = [];

		for (let a in status["ipv4-address"])
			push(ipv4, sprintf("%s/%d", a.address, a.mask));

		iface.ipv4.addresses = ipv4;

		if (vsi && name in vsi)
			iface.ipv4.dhcp_vsi = vsi[name];
	}

	if (length(status["ipv6-address"])) {
		iface.ipv6.addresses = status["ipv6-address"];
		for (let key, addr in iface.ipv6.addresses) {
			if (!addr.mask)
				continue;
			addr.address = sprintf("%s/%s", addr.address, addr.mask);
			delete addr.mask;
		}
	}

	if (length(status["dns-server"]))
		iface.dns_servers = status["dns-server"];

	if (length(status.data) && status.data.ntpserver)
		iface.ntp_server = status.data.ntpserver;

	if (length(status.data) && status.data.leasetime && status.proto == "dhcp") {
		iface.ipv4.leasetime = status.data.leasetime;
		iface.ipv4.dhcp_server = status.data.dhcpserver;
	}

	if (length(ipv6leases) &&
	    length(ipv6leases.device) &&
	    length(ipv6leases.device[status.device]) &&
	    length(ipv6leases.device[status.device].leases)) {
		let leases = [];

		for (let l in ipv6leases.device[status.device].leases) {
			let lease = {};

			lease.hostname = l.hostname;
			lease.addresses = [];
			for (let addr in l["ipv6-addr"])
				push(lease.addresses, addr.address);
			push(leases, lease);
		}

		if (length(leases))
			iface.ipv6.leases = leases
	}

	let macs = [];

	if (length(topology)) {
		let clients = [];

		for (let mac, topo in topology) {
			if (topo.interface != d[".name"] ||
			    !length(topo.fdb) ||
			    (!length(topo["ipv4"]) && !length(topo["ipv6"])))
				continue;

			let client = {};

			if (length(ip4leases[mac]))
				push(ipv4leases, ip4leases[mac]);

			client.mac = mac;
			if (length(topo["ipv4"]))
				client.ipv4_addresses = topo["ipv4"];
			else if (snoop && snoop[mac])
				client.ipv4_addresses = [ snoop[mac] ];

			if (length(topo["ipv6"]))
				client.ipv6_addresses = topo["ipv6"];

			client.ports = [];
			for (let k in topo.fdb)
				push(client.ports, lookup_port(k));
			let fp = get_fingerprint(mac, client.ports);
			if (fp)
				client.fingerprint = fp;
			client.last_seen = topo.last_seen;
			if (index(stats.types, 'clients') >= 0) {
				push(clients, client);
				push(macs, mac);
			}
		}

		if (length(ipv4leases))
			iface.ipv4.leases = ipv4leases;


		if (length(clients))
			iface.clients = clients;
	}

	if (index(stats.types, 'ssids') >= 0 && length(wifistatus)) {
		let ssids = [];
		let counter = 0;

		for (let radio, data in wifistatus) {
			for (let k, vap in data.interfaces) {
				if (!length(vap.config) ||
				    !length(vap.config.network) ||
				    !wifiiface[vap.ifname])
					continue;
				let wif = wifiiface[vap.ifname];
				if (!(name in vap.config.network) && !is_mesh(d, wif))
					continue;
				let ssid = {
					radio:{"$ref": sprintf("#/radios/%d", counter)},
					phy: data.config.path,
					band: uc(data.config.band)
				};
				ssid.location = wireless[vap.section]?.ucentral_path || '';
				ssid.ssid = wif.ssid || vap.config.mesh_id;
				ssid.mode = wif.mode;
				ssid.bssid = wif.bssid;
				ssid.frequency = uniq(wif.frequency);
				for (let k, v in stations) {
					let vlan = split(k, '-v');
					if (vlan[0] != vap.ifname)
						continue;
					if (vlan[1])
						for (let k, assoc in v)
							assoc.dynamic_vlan = +vlan[1];
					ssid.associations = [ ...(ssid.associations || []), ...v ];
				}
				for (let assoc in ssid.associations) {
					let fp = get_fingerprint(assoc.station);
					if (fp)
					 	assoc.fingerprint = fp;
					if (length(ip4leases[assoc.station]))
			                           assoc.ipaddr_v4 = ip4leases[assoc.station];
					else if (snoop && snoop[assoc.station]) {
				 		assoc.ipaddr_v4 = snoop[assoc.station];
						if (!(assoc.station in macs)) {
							if (!iface.clients)
								iface.clients = [];
							let client = {
								"mac": assoc.station,
								"ipv4_addresses": [ snoop[assoc.station] ],
								"ports": [ vap.ifname ]
							};
							push(iface.clients, client);
						}
					}

					assoc.delta_counters = stations_deltas(assoc, vap.ifname);
				}

				ssid.iface = vap.ifname;
				if (ports[vap.ifname]?.counters) {
					ssid.counters = ports[vap.ifname].counters || {};
					ssid.delta_counters = ports_deltas(vap.ifname);
				}
				if (is_mesh(d, wif)) {
					ssid.counters = ports['batman_mesh'].counters;
					ssid['mesh-path'] = mesh[vap.ifname];
				}
				if (dyn_vlans[vap.ifname]) {
					ssid.vlan_ifaces = [];
					for (let vlan in dyn_vlans[vap.ifname]) {
						let vid = +split(vlan, '-v')[1];
						push(dyn_vids, vid);
						push(ssid.vlan_ifaces, { ...(ports[vlan]?.counters || {}), ...{ vid} });
					}
				}
				push(ssids, ssid);
			}
			counter++;
		}
		if (length(ssids))
			iface.ssids = ssids;
	}

	iface.counters = ports[name]?.counters || {};
	if (role == 'up') {
		iface.counters.rx_bytes = 0;
		iface.counters.tx_bytes = 0;
		iface.counters.rx_packets = 0;
		iface.counters.tx_packets = 0;
		for (let port in iface_ports)
			iface_add_counters(iface, vlan, port); 

	} else {
		iface.delta_counters = ports_deltas(name); 
	}

	if (!length(iface.ipv4))
		delete iface.ipv4;
	if (!length(iface.ipv6))
		delete iface.ipv6;
});

dyn_vids = uniq(dyn_vids);
if (length(dyn_vids)) {
	state.dynamic_vlans = [];
	for (let id in dyn_vids) {
		let dyn = {
			vid: id,
			tx_bytes: 0,
			tx_packets: 0,
			rx_bytes: 0,
			rx_packets: 0
		};
		for (let k, dev in devstats) {
			for (let k, vid in dev) {
				if (vid.vid != id)
					continue;
				dyn.tx_bytes += vid.tx.bytes;
				dyn.tx_packets += vid.tx.packets;
				dyn.rx_bytes += vid.rx.bytes;
				dyn.rx_packets += vid.rx.packets;
			}		
		}
		push(state.dynamic_vlans, dyn);
	}
}

if (length(poe)) {
	state.poe = {};
	state.poe.consumption = poe.consumption;
	state.poe.ports = [];
	for (let k, v in poe.ports) {
		let port = {
			id: replace(k, 'lan', ''),
			status: v.status
		};
		if (v.consumption)
			port.consumption = v.consumption;
		push(state.poe.ports, port);
	}
}

if (length(gps) && gps.latitude)
	state.gps = {
		latitude: gps.latitude,
		longitude: gps.longitude,
		elevation: gps.elevation
	};

if (length(captive)) {
	let res = {};
	let t = time();

	for (let c, val in captive) {
		res[c] = {
			status: val.state ? 'Authenticated' : 'Garden',
			idle: val.idle || 0,
			time: val.data.connect ? t - val.data.connect : 0,
			ip4addr: val.ip4addr || '',
			ip6addr: val.ip6addr || '',
			packets_ul: val.packets_ul || 0,
			bytes_ul: val.bytes_ul || 0,
			packets_dl: val.packets_dl || 0,
			bytes_dl: val.bytes_dl || 0,
			username: val?.data?.radius?.request?.username || '',
		};
	}
	state.captive = res;
}

function sysfs_net(iface, prop) {
	let f = fs.open(sprintf("/sys/class/net/%s/%s", iface, prop), "r");
	let val = 0;

	if (f) {
		val = replace(f.read("all"), '\n', '');
		f.close();
	}
	if (val === null)
		val = 0;
	return val;
}

function link_state_name(name) {
	let names = {
		'wan': 'upstream',
		'lan': 'downstream'
	};
	return names[name] || name;
}

function get_vlan_id_for_port(sw_port, switch_name) {
	let current_vlan;
	let swconfig_cmd = "swconfig dev " + switch_name + " show";
	let sw_status = fs.popen(swconfig_cmd);

	for (let line; (line = sw_status.read("line")) != null; ){
		line = trim(line);

		let vlan_info = match(line, /^VLAN\s+(\d+):$/);
		if (vlan_info) {
			current_vlan = vlan_info[1];
			continue;
		}

		let port_info = match(line, /^ports:\s+(.+)$/);
		if (port_info && current_vlan) {
            let ports = split(port_info[1], /\s+/);

			for (let port_num in ports) {
				if (port_num == sw_port) {
					sw_status.close();
					return current_vlan;
				}
			}
		}
	}

	sw_status.close();
	return null;
}

function get_sw_port_status(sw_port, switch_name, prop) {
	let speed_regexp, duplex_regexp, val;

	let swconfig_cmd = "swconfig dev " + switch_name + " port " + sw_port + " show";
	let sw_status = fs.popen(swconfig_cmd);

	for (let line; (line = sw_status.read("line")) != null; ){
		line = trim(line);

		switch (prop) {
			case 'carrier':
				if (match(line, /link:up/))
					val = 1;
				else if (match(line, /link:down/))
					val = 0;
				break;
			case 'speed':
				speed_regexp = match(line, /speed:([0-9]+)/);
				if (speed_regexp)
					val = speed_regexp[1];
				break;
			case 'duplex':
				duplex_regexp = match(line, /(full|half)-duplex/);
				if (duplex_regexp)
					val = duplex_regexp[1];
				break;
		}
	}

	sw_status.close();
	return val;
}

if (length(capab.network)) {
	let link = {};
	let lldp_peers = {};
	let vlan_id;

	for (let name, net in capab.network) {
		let link_name = link_state_name(name);
		link[link_name] = {};
		lldp_peers[link_name] = {};

		for (let iface in capab.network[name]) {
			let state = {};
			let lldp_state = {};
			let name = lookup_port(iface);

			state.carrier = +sysfs_net(iface, "carrier");
			if (state.carrier) {
				state.speed = +sysfs_net(iface, "speed");
				state.duplex = sysfs_net(iface, "duplex");
			}

			if (length(capab.switch_ports)) {
				for (let eth_port, sw_port_info in capab.switch_ports) {
					let sw_iface = split(iface, ":");
					if (sw_iface[0] == eth_port) {
						vlan_id = get_vlan_id_for_port(sw_iface[1], sw_port_info['name']);

						if (vlan_id) {
							iface = eth_port + "." + vlan_id;
						}

						state.carrier = get_sw_port_status(sw_iface[1], sw_port_info['name'], "carrier");
						if (state.carrier) {
							state.speed = get_sw_port_status(sw_iface[1], sw_port_info['name'], "speed");
							state.duplex = get_sw_port_status(sw_iface[1], sw_port_info['name'], "duplex");
						}
					}
				}
			}

			if (ports[iface]?.counters) {
				state.counters = ports[iface].counters;
				state.delta_counters = ports_deltas(iface);
			}
			link[link_name][name] = state;

			let lldp_neigh = [];
			for (let l in lldp)
				if (l.ifname == iface) {
					delete l.ifname;
					push(lldp_neigh, l);
				}
			if (length(lldp_neigh))
				lldp_peers[link_name][name] = lldp_neigh;

		}
	}
	state["link-state"] = link;
	if (index(stats.types, 'lldp') >= 0) 
		state["lldp-peers"] = lldp_peers;
}

if (ieee8021x)
	state.ieee8021x = {};

if (fingerprint) {
	switch(finger_config?.mode) {
	case 'raw-data':
		state.fingerprint = fingerprint;
		break;
	case 'final':
		fs.writefile('/tmp/finger.state', finger_state);
		break;
	}
}

state.version = 1;
printf("%.J\n", state);

let msg = {
	uuid: cfg.uuid || 1,
	serial: cursor.get("ucentral", "config", "serial"),
	state
};

if (telemetry) {
	ctx.call("ucentral", "telemetry", { "event": "state", "payload": msg });
	let f = fs.open("/tmp/ucentral.telemetry", "w");
	if (f) {
		f.write(msg);
		f.close();
	}
	return;
}

ctx.call("ucentral", "stats", msg);
let f = fs.open("/tmp/ucentral.state", "w");
if (f) {
	f.write(msg);
	f.close();
}
else {
	printf("Unable to open %s for writing: %s", statefile_path, fs.error());
}
