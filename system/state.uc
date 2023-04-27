#!/usr/bin/ucode
push(REQUIRE_SEARCH_PATH, '/usr/share/ucentral/*.uc');
let fs = require("fs");

let uci = require("uci");
let ubus = require("ubus");
let cfgfile = fs.open("/etc/ucentral/ucentral.active", "r");
let cfg = json(cfgfile.read("all"));
let capabfile = fs.open("/etc/ucentral/capabilities.json", "r");
let capab = json(capabfile.read("all"));

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

/* find out what telemetry we should gather */
let stats;
if (!length(stats)) {
	cursor.load("ustats");
	stats = cursor.get_all("ustats", "stats");
}

let delta = 1;
if (telemetry)
	delta = 0;

let public_ip_file  = "/tmp/public_ip";
let public_ip = "";
if (cfg.public_ip_lookup) {
        if(!fs.access(public_ip_file))
                let result = system(sprintf("/usr/bin/curl -m 3 %s -o %s", cfg.public_ip_lookup, public_ip_file));
        let online_file = fs.open(public_ip_file);
        public_ip = online_file.read("all") || '';
        online_file.close();
}

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
let devstats = ctx.call('udevstats', 'dump');
let devices = ctx.call("network.device", "status");

let lldp = [];
let wireless = cursor.get_all("wireless");
let snoop = ctx.call("dhcpsnoop", "dump");
let captive = ctx.call("spotfilter", "client_list", { "interface": "hotspot"});

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
let system = ctx.call("system", "info");
state.unit.localtime = system.localtime;
state.unit.uptime = system.uptime;
state.unit.load = system.load;
state.unit.memory.total = system.memory.total;
state.unit.memory.free = system.memory.free;
state.unit.memory.cached = system.memory.cached;
state.unit.memory.buffered = system.memory.buffered;

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
	radio.survey = [];
	for (let k, v in survey.survey)
		if (v.frequency in radio.frequency)
			push(radio.survey, v);
	delete radio.in_use;
	radio.phy = data.config.path;
	if (wifiphy[data.config.path] && wifiphy[data.config.path].temperature)
		radio.temperature = wifiphy[data.config.path].temperature;
	radio.band = wifiphy[data.config.path].band;
	push(state.radios, radio);
}
if (!length(state.radios))
	delete state.radios;


function iface_add_counters(counters, vlan, port) {
	if (!devstats[port])
		return;
	for (let k, vid in devstats[port]) {
		if (vid.vid != vlan)
			continue;
		counters.tx_bytes += vid.tx.bytes;
		counters.tx_packets += vid.tx.packets;
		counters.rx_bytes += vid.rx.bytes;
		counters.rx_packets += vid.rx.packets;
	}
}

function is_mesh(net, wif) {
	if (!net.batman)
		return false;
	if (wif.mode != 'mesh')
		return false;
	return true;
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

	if (devices && length(devices[role]["bridge-members"]))
		iface_ports = devices[role]["bridge-members"];
	iface.uptime = status.uptime || 0;

	if (length(status["ipv4-address"])) {
		let ipv4 = [];

		for (let a in status["ipv4-address"])
			push(ipv4, sprintf("%s/%d", a.address, a.mask));

		iface.ipv4.addresses = ipv4;
		if( cfg.public_ip_lookup && length(public_ip))
                        iface.ipv4.public_ip = public_ip;
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

			client.ports = topo.fdb;
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
					ssid.associations = [ ...(ssid.associations || []), ...v ];
				}
				for (let assoc in ssid.associations) {
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
				}

				ssid.iface = vap.ifname;
				if (ports[vap.ifname]?.counters)
					ssid.counters = ports[vap.ifname].counters || {};
				if (is_mesh(d, wif)) {
					ssid.counters = ports['batman_mesh'].counters;
					ssid['mesh-path'] = mesh[vap.ifname];
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
			iface_add_counters(iface.counters, vlan, port); 

	}

	if (!length(iface.ipv4))
		delete iface.ipv4;
	if (!length(iface.ipv6))
		delete iface.ipv6;
});

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

if (length(capab.network)) {
	let link = {};
	let lldp_peers = {};

	for (let name, net in capab.network) {
		let link_name = link_state_name(name);
		link[link_name] = {};
		lldp_peers[link_name] = {};

		for (let iface in capab.network[name]) {
			let state = {};
			let lldp_state = {};

			state.carrier = +sysfs_net(iface, "carrier");
			if (state.carrier) {
				state.speed = +sysfs_net(iface, "speed");
				state.duplex = sysfs_net(iface, "duplex");
			}
			if (ports[iface]?.counters)
				state.counters = ports[iface].counters;
			link[link_name][iface] = state;

			let lldp_neigh = [];
			for (let l in lldp)
				if (l.ifname == iface) {
					delete l.ifname;
					push(lldp_neigh, l);
				}
			if (length(lldp_neigh))
				lldp_peers[link_name][iface] = lldp_neigh;

		}
	}
	state["link-state"] = link;
	if (index(stats.types, 'lldp') >= 0) 
		state["lldp-peers"] = lldp_peers;
}

state.version = 1;
printf("%s\n", state);

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
