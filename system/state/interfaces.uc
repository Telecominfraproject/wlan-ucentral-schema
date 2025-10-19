import * as fs from 'fs';
import * as network_module from './network.uc';
import * as telemetry_module from './telemetry.uc';
import * as fingerprint_module from './fingerprint.uc';
import * as wifi_module from './wifi.uc';

export function collect(state) {
	/* Collect data via ubus */
	let ipv6leases = global.ubus.call("dhcp", "ipv6leases");
	let topology = global.topology_mac;
	
	/* Load VSI data */
	let vsifile = fs.open("/tmp/udhcpc-vsi.json", "r");
	let vsi = vsifile ? json(vsifile.read("all")) : null;

	global.uci.load("network");
	global.uci.foreach("network", "interface", function(d) {
		let name = d[".name"];
		if (name == "loopback")
			return;
		if (index(name, "_") >= 0)
			return;
		if (!d.ucentral_path)
			return;
		let role = split(name, /[[:digit:]]/)[0];
		let vlan = split(name, 'v')[1];
		let iface_ports;

		let iface = { name, location: d.ucentral_path, ipv4:{}, ipv6:{} };
		let ipv4leases = [];

		push(state.interfaces, iface);

		let status = global.ubus.call(sprintf("network.interface.%s", name) , "status");

		if (!length(status))
			return;

		if (global.devices && global.devices[role] && length(global.devices[role]["bridge-members"]))
			iface_ports = global.devices[role]["bridge-members"];
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

				if (length(global.ip4leases[mac]))
					push(ipv4leases, global.ip4leases[mac]);

				client.mac = mac;
				if (length(topo["ipv4"]))
					client.ipv4_addresses = topo["ipv4"];
				else if (global.snoop && global.snoop[mac])
					client.ipv4_addresses = [ global.snoop[mac] ];

				if (length(topo["ipv6"]))
					client.ipv6_addresses = topo["ipv6"];

				client.ports = [];
				for (let k in topo.fdb)
					push(client.ports, network_module.lookup_port(k, global.select_ports));
				let fp = fingerprint_module.get_fingerprint_for_mac(mac, client.ports);
				if (fp)
					client.fingerprint = fp;
				client.last_seen = topo.last_seen;
				if (index(global.stats.types, 'clients') >= 0) {
					push(clients, client);
					push(macs, mac);
				}
			}

			if (length(ipv4leases))
				iface.ipv4.leases = ipv4leases;


			if (length(clients))
				iface.clients = clients;
		}

		global.macs = macs;
		let ssids = wifi_module.collect_wifi_ssids(iface);
		if (length(ssids))
			iface.ssids = ssids;

		if (global.ports && global.ports[name]?.counters)
			iface.counters = global.ports[name].counters;
		else
			iface.counters = {};
		if (role == 'up') {
			iface.counters.rx_bytes = 0;
			iface.counters.tx_bytes = 0;
			iface.counters.rx_packets = 0;
			iface.counters.tx_packets = 0;
			for (let port in iface_ports)
				network_module.iface_add_counters(iface, vlan, port, global.previous); 

		} else {
			iface.delta_counters = telemetry_module.ports_deltas(name, global.ports, global.previous); 
		}

		if (!length(iface.ipv4))
			delete iface.ipv4;
		if (!length(iface.ipv6))
			delete iface.ipv6;
	});
};
