{%
let interfaces = services.lookup_interfaces_by_ssids("captive");
let enable = length(interfaces);
if (enable != 1)
	return;

for (let name, data in captive.interfaces) {
	/* spotfilter resolves device_macaddr with SIOCGIFHWADDR, so it has to be a
	 * kernel netdev name. Use the name interface.uc recorded rather than
	 * deriving it, since a type=bridge interface is br-<network> while the
	 * bridge-vlan path is an 8021q device named <network>. */
	let class0 = {
		index: 0,
		fwmark: 1,
		fwmark_mask: 127
	};
	let netdev = captive.netdev[split(name, '_')[0]];
	if (netdev)
		class0.device_macaddr = netdev;

	let config = {
		name,
		devices: [],
		config: {
			default_class: 0,
			default_dns_class: 1,
			client_autoremove: false,
			class: [
				class0,
				{
					index: 1,
					fwmark: 2,
					fwmark_mask: 127
				}
			],
			whitelist: [
	                        {
	                                "class": 1,
	                                "hosts": [ ],
					"address": [],
	                        }
	                ]
		}
	};

	for (let iface in data.iface)
		push(config.devices, 'wlanc' + iface);

	for (let fqdn in data.walled_garden_fqdn)
		push(config.config.whitelist[0].hosts, fqdn);

	for (let ipaddr in data.walled_garden_ipaddr)
		push(config.config.whitelist[0].address, ipaddr);

	let fs = require('fs');
	let file = fs.open('/tmp/spotfilter-' + name + '.json', 'w');
	file.write(config);
	file.close();
	services.set_enabled("uhttpd", true)
}
%}
