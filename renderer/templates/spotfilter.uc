{%
	// Constants
	const SPOTFILTER_DEFAULTS = {
		default_class: 0,
		default_dns_class: 1,
		client_autoremove: false
	};

	const SPOTFILTER_CLASSES = [
		{
			index: 0,
			fwmark: 1,
			fwmark_mask: 127
		},
		{
			index: 1,
			fwmark: 2,
			fwmark_mask: 127
		}
	];

	const WHITELIST_DEFAULTS = {
		class: 1,
		hosts: [],
		address: []
	};

	// Helper functions

	// has_ functions - check for existence/availability
	function has_captive_interfaces() {
		let interfaces = services.lookup_interfaces_by_ssids("captive");
		return length(interfaces) == 1;
	}

	function has_walled_garden_fqdns(data) {
		return data.walled_garden_fqdn && length(data.walled_garden_fqdn) > 0;
	}

	function has_walled_garden_addresses(data) {
		return data.walled_garden_ipaddr && length(data.walled_garden_ipaddr) > 0;
	}

	// normalize_ functions - data transformation
	function normalize_device_macaddr(name) {
		return split(name, '_')[0];
	}

	function normalize_interface_devices(data) {
		let devices = [];
		for (let iface in data.iface)
			push(devices, 'wlanc' + iface);
		return devices;
	}

	function normalize_whitelist_hosts(data) {
		let hosts = [];
		for (let fqdn in data.walled_garden_fqdn)
			push(hosts, fqdn);
		return hosts;
	}

	function normalize_whitelist_addresses(data) {
		let addresses = [];
		for (let ipaddr in data.walled_garden_ipaddr)
			push(addresses, ipaddr);
		return addresses;
	}

	// Configuration generation functions
	function generate_spotfilter_config(name, data) {
		let config = {
			name,
			devices: normalize_interface_devices(data),
			config: {
				default_class: SPOTFILTER_DEFAULTS.default_class,
				default_dns_class: SPOTFILTER_DEFAULTS.default_dns_class,
				client_autoremove: SPOTFILTER_DEFAULTS.client_autoremove,
				class: [
					{
						index: SPOTFILTER_CLASSES[0].index,
						device_macaddr: normalize_device_macaddr(name),
						fwmark: SPOTFILTER_CLASSES[0].fwmark,
						fwmark_mask: SPOTFILTER_CLASSES[0].fwmark_mask
					},
					{
						index: SPOTFILTER_CLASSES[1].index,
						fwmark: SPOTFILTER_CLASSES[1].fwmark,
						fwmark_mask: SPOTFILTER_CLASSES[1].fwmark_mask
					}
				],
				whitelist: [
					{
						class: WHITELIST_DEFAULTS.class,
						hosts: normalize_whitelist_hosts(data),
						address: normalize_whitelist_addresses(data)
					}
				]
			}
		};

		return config;
	}

	function generate_spotfilter_file(name, config) {
		let file = fs.open('/tmp/spotfilter-' + name + '.json', 'w');
		file.write(config);
		file.close();
	}

	// Main logic
	if (!has_captive_interfaces())
		return;

	for (let name, data in captive.interfaces) {
		let config = generate_spotfilter_config(name, data);
		generate_spotfilter_file(name, config);
		services.set_enabled("uhttpd", true);
	}
%}
