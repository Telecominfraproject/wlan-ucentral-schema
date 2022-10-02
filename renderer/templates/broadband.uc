{%
/* find and replace the first upstream interface using vid with
 * the broadband settings */
let uplink = ethernet.get_interface("upstream", 0);
if (!uplink)
	return;

if (index([ "wwan", "pppoe", "static", "dhcp", "wds" ], broadband.protocol) < 0)
	return;

for (let k, v in uplink)
	if (index([ "vlan", "index" ], k) < 0)
		delete uplink[k];

uplink.name = "ISP_UPLINK";
uplink.role = "upstream";
uplink.vlan = {	id: 0 };
uplink.metric = 1;

if (broadband.protocol == "wwan") {
	let wwan = { };

	wwan.protocol = 'wwan';
	wwan.modem_type = broadband['modem-type'] || 'wwan';
	wwan.pin_code = broadband['pin-code'] || '';
	wwan.access_point_name = broadband['access-point-name'] || '';
	wwan.packet_data_protocol = broadband['packet-data-protocol'] || 'dual-stack';
	wwan.authentication_type = broadband['authentication-type'] || 'none';
	wwan.username = broadband.username || '';
	wwan.password = broadband.password || '';

	uplink.broad_band = wwan;
}

if (broadband.protocol == "pppoe") {
	let pppoe = { };

	pppoe.protocol = 'pppoe';
	pppoe.username = broadband['user-name'] || '';
	pppoe.password = broadband.password || '';
	pppoe.timeout = broadband.timeout || '30';

	uplink.broad_band = pppoe;
	uplink.ethernet = [
		{
			"select_ports": [ "WAN*" ]
		}
	];
}

if (broadband.protocol == "static") {
	uplink.ethernet = [
		{
			"select_ports": [ "WAN*" ]
		}
	];
	uplink.ipv4 = {
		addressing: "static",
		subnet: broadband['ipv4-address'],
		gateway: broadband['ipv4-gateway'],
		use_dns: broadband['use-dns'],
	};
}

if (broadband.protocol == "dhcp") {
	uplink.ethernet = [
		{
			"select_ports": [ "WAN*" ]
		}
	];
	uplink.ipv4 = {
		addressing: "dynamic",
	};
}

if (broadband.protocol == "wds") {
	uplink.ipv4 = {
		addressing: "dynamic",
	};

	let wds = {
		"name": broadband.ssid,
		"wifi_bands": [
			"2G", "5G"
		],
		"bss_mode": "wds-sta",
		"encryption": {
			"proto": broadband.encryption,
			"key": broadband.passphrase,
			"ieee80211w": "optional"
		}
	};

	if (!uplink.ssids)
		uplink.ssids = [ wds ];
	else
		push(uplink.ssids, wds);
}

%}
