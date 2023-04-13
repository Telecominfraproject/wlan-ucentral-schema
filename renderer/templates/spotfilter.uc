{%
let interfaces = services.lookup_interfaces_by_ssids("captive");
let enable = length(interfaces);
if (enable != 1)
	return;

for (let name, data in captive.interfaces) {
	let config = {
		name,
		devices: [],
		config: {
			default_class: 0,
			default_dns_class: 1,
			client_autoremove: false,
			class: [
				{
					index: 0,
					device_macaddr: split(name, '_')[0],
					fwmark: 1,
					fwmark_mask: 127
				}, {
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
