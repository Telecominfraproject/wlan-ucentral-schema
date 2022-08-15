{%
let interfaces = services.lookup_interfaces_by_ssids("captive");
let enable = length(interfaces);
if (enable != 1)
	return;
let name;
for (let interface in interfaces)
	name = ethernet.calculate_name(interface);


let config = {
	name: "hotspot",
	devices: [],
	config: {
		default_class: 0,
		default_dns_class: 1,
		class: [
			{
				index: 0,
				device_macaddr: name,
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
                                "hosts": [ ]
                        }
                ]
	}
};

for (let id = 0; id < captive.next; id++)
	push(config.devices, 'wlancaptive' + id);

for (let fqdn in state.services.captive.walled_garden_fqdn)
	push(config.config.whitelist[0].hosts, fqdn);

let fs = require('fs');
let file = fs.open('/tmp/spotfilter.json', 'w');
file.write(config);
file.close();
services.set_enabled("uhttpd", true)
%}
