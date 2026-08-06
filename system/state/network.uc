import * as fs from 'fs';

export function discover_ports() {
	let roles = {};

	/* Derive ethernet port names and roles from default config */
	for (let role, spec in global.capab.network) {
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
};

export function lookup_port(netdev, select_ports) {
	for (let k, v in select_ports)
		if (v.netdev == netdev)
			return k;
	return 'unknown';
};

export function iface_add_counters(iface, vlan, port, previous) {
	if (!global.devstats || !global.devstats[port])
		return;
	for (let k, vid in global.devstats[port]) {
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
};

export function get_dynamic_vlans() {
	let dyn_vlans = {};
	let dyn_vids = [];
	
	if (global.devices?.up) for (let k, vlan in global.devices.up['bridge-vlans']) {
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
	
	return dyn_vlans;
};

export function prepare_dhcp_leases() {
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
	
	return ip4leases;
};

/* only trust a local dnsmasq lease if its address falls inside one of the
 * interface's own IPv4 subnets - a stale lease (e.g. left behind after an
 * SSID was moved to another network) would otherwise shadow the address
 * snooped from the real dhcp exchange */
export function lease_matches_iface(lease, iface) {
	if (!length(iface.ipv4.addresses))
		return true;

	let ip = iptoarr(lease.address);

	if (length(ip) != 4)
		return false;

	for (let cidr in iface.ipv4.addresses) {
		let net = split(cidr, "/");
		let sub = iptoarr(net[0]);
		let bits = net[1] ? int(net[1]) : -1;

		if (length(sub) != 4 || bits < 0 || bits > 32)
			continue;

		let mask = (0xffffffff << (32 - bits)) & 0xffffffff;

		if ((((ip[0] << 24) | (ip[1] << 16) | (ip[2] << 8) | ip[3]) & mask) ==
		    (((sub[0] << 24) | (sub[1] << 16) | (sub[2] << 8) | sub[3]) & mask))
			return true;
	}

	return false;
};

