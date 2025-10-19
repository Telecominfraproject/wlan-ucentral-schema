import * as fs from 'fs';
import * as network_module from './network.uc';

function prepare_lldp_cache() {
	let lldp = [];
	
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
	
	return lldp;
}

export function collect_lldp_peers(state) {
	if (!length(global.capab.network) || index(global.stats.types, 'lldp') < 0)
		return;
	
	// Prepare LLDP cache internally
	let lldp_data = prepare_lldp_cache();
	
	
	let lldp_peers = {};

	for (let name, net in global.capab.network) {
		let link_name = (name == 'wan') ? 'upstream' : ((name == 'lan') ? 'downstream' : name);
		lldp_peers[link_name] = {};

		for (let iface in global.capab.network[name]) {
			let lldp_state = {};
			let port_name = network_module.lookup_port(iface, global.select_ports);

			let lldp_neigh = [];
			for (let l in lldp_data)
				if (l.ifname == iface) {
					delete l.ifname;
					push(lldp_neigh, l);
				}
			if (length(lldp_neigh))
				lldp_peers[link_name][port_name] = lldp_neigh;
		}
	}
	
	if (length(lldp_peers))
		state["lldp-peers"] = lldp_peers;
};

