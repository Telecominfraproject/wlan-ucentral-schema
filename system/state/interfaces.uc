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

		/* When dual-stack dynamic is configured, common.uc creates a proto=none
		 * base interface (e.g. up0v0) plus _4 (dhcp) and _6 (dhcpv6) siblings.
		 * Query those sub-interfaces so we capture the actual IP addresses. */
		let status_v4 = global.ubus.call(sprintf("network.interface.%s_4", name), "status");
		let status_v6 = global.ubus.call(sprintf("network.interface.%s_6", name), "status");

		if (global.devices && global.devices[role] && length(global.devices[role]["bridge-members"]))
			iface_ports = global.devices[role]["bridge-members"];
		iface.uptime = status.uptime || 0;

		/* Prefer addresses from the _4 sub-interface, fall back to base */
		let ipv4_src = (length(status_v4) && length(status_v4["ipv4-address"])) ? status_v4 : status;
		if (length(ipv4_src["ipv4-address"])) {
			let ipv4 = [];

			for (let a in ipv4_src["ipv4-address"])
				push(ipv4, sprintf("%s/%d", a.address, a.mask));

			iface.ipv4.addresses = ipv4;

			if (vsi && name in vsi)
				iface.ipv4.dhcp_vsi = vsi[name];
		}

		/* Prefer addresses from the _6 sub-interface, fall back to base */
		let ipv6_src = (length(status_v6) && length(status_v6["ipv6-address"])) ? status_v6 : status;
		if (length(ipv6_src["ipv6-address"])) {
			iface.ipv6.addresses = ipv6_src["ipv6-address"];
			for (let key, addr in iface.ipv6.addresses) {
				if (!addr.mask)
					continue;
				addr.address = sprintf("%s/%s", addr.address, addr.mask);
				delete addr.mask;
			}
		}

		/* Merge DNS servers from base, _4 and _6 */
		let dns_servers = [];
		for (let src in [status, status_v4, status_v6])
			if (length(src) && length(src["dns-server"]))
				for (let s in src["dns-server"])
					if (index(dns_servers, s) < 0)
						push(dns_servers, s);
		if (length(dns_servers))
			iface.dns_servers = dns_servers;

		/* Check base and _4 for NTP server */
		let ntp_src = (length(status_v4) && length(status_v4.data) && status_v4.data.ntpserver) ? status_v4 : status;
		if (length(ntp_src.data) && ntp_src.data.ntpserver)
			iface.ntp_server = ntp_src.data.ntpserver;

		/* Check base and _4 for DHCP lease info */
		let dhcp_src = (length(status_v4) && length(status_v4.data) && status_v4.data.leasetime && status_v4.proto == "dhcp") ? status_v4 : status;
		if (length(dhcp_src.data) && dhcp_src.data.leasetime && dhcp_src.proto == "dhcp") {
			iface.ipv4.leasetime = dhcp_src.data.leasetime;
			iface.ipv4.dhcp_server = dhcp_src.data.dhcpserver;
		}

		/* Use _6 sub-interface device for IPv6 lease lookup if available */
		let ipv6_dev = (length(status_v6) && status_v6.device) ? status_v6.device : status.device;
		if (length(ipv6leases) &&
		    length(ipv6leases.device) &&
		    length(ipv6leases.device[ipv6_dev]) &&
		    length(ipv6leases.device[ipv6_dev].leases)) {
			let leases = [];

			for (let l in ipv6leases.device[ipv6_dev].leases) {
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
