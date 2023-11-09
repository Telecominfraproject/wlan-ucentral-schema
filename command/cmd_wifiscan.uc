let verbose = args?.verbose == null ? true : args.verbose;
let active = args?.active ? true : false;
let bandwidth = args?.bandwidth || 0;
let override_dfs = args?.override_dfs ? true : false;
let nl = require("nl80211");
let rtnl = require("rtnl");
let def = nl.const;

if (!ctx) {
        ubus = require("ubus");
        ctx = ubus.connect();
}

const SCAN_FLAG_AP = (1<<2);
const frequency_list_2g = [ 2412, 2417, 2422, 2427, 2432, 2437, 2442,
			  2447, 2452, 2457, 2462, 2467, 2472, 2484 ];
const frequency_list_5g = { '3': [ 5180, 5260, 5500, 5580, 5660, 5745 ],
			  '2': [ 5180, 5220, 5260, 5300, 5500, 5540,
				 5580, 5620, 5660, 5745, 5785, 5825,
				 5865, 5920, 5960 ],
			  '1': [ 5180, 5200, 5220, 5240, 5260, 5280,
				 5300, 5320, 5500, 5520, 5540, 5560,
				 5580, 5600, 5620, 5640, 5660, 5680,
				 5700, 5720, 5745, 5765, 5785, 5805,
				 5825, 5845, 5865, 5885 ],
};
const frequency_offset = { '80': 30, '40': 10 };
const frequency_width = { '80': 3, '40': 2, '20': 1 };
const IFTYPE_STATION = 2;
const IFTYPE_AP = 3;
const IFTYPE_MESH = 7;
const IFF_UP = 1;

function frequency_to_channel(freq) {
	/* see 802.11-2007 17.3.8.3.2 and Annex J */
	if (freq == 2484)
		return 14;
	else if (freq < 2484)
		return (freq - 2407) / 5;
	else if (freq >= 4910 && freq <= 4980)
		return (freq - 4000) / 5;
	else if (freq < 5935) /* DMG band lower limit */
		return (freq - 5000) / 5;
	else if (freq == 5935)
		return 2;
	else if (freq >= 5955 && freq <= 7115)
		return ((freq - 5955) / 5) + 1;
	else if (freq >= 58320 && freq <= 64800)
		return (freq - 56160) / 2160;
	return 0;
}

function iface_get(wdev) {
	let params = { dev: wdev };
	let res = nl.request(def.NL80211_CMD_GET_INTERFACE, wdev ? null : def.NLM_F_DUMP, wdev ? params : null);

	if (res === false)
		warn("Unable to lookup interface: " + nl.error() + "\n");
	return res || [];
}

function iface_find(wiphy, types, ifaces) {
	if (!ifaces)
		ifaces = iface_get();
	for (let iface in ifaces) {
		if (iface.wiphy != wiphy)
			continue;
		if (iface.iftype in types)
			return iface;
	}
	return;
}

function scan_trigger(wdev, frequency, width) {
	let params = { dev: wdev, scan_flags: SCAN_FLAG_AP };

	if (frequency && type(frequency) == 'array') {
		params.scan_frequencies = frequency;
	}
	else if (frequency && width) {
		params.wiphy_freq = frequency;
		params.center_freq1 = frequency + frequency_offset[width];
		params.channel_width = frequency_width[width];
	}

	if (active)
		params.scan_ssids = [ '' ];

	//printf("%.J\n", params);
	let res = nl.request(def.NL80211_CMD_TRIGGER_SCAN, 0, params);

	if (res === false)
		die("Unable to trigger scan: " + nl.error() + "\n");

	else
		res = nl.waitfor([
			def.NL80211_CMD_NEW_SCAN_RESULTS,
			def.NL80211_CMD_SCAN_ABORTED
		], (frequency && width) ? 500 : 5000);

	if (!res)
		warn("Netlink error while awaiting scan results: " + nl.error() + "\n");

	else if (res.cmd == def.NL80211_CMD_SCAN_ABORTED)
		warn("Scan aborted by kernel\n");
}

function trigger_scan_width(wdev, freqs, width) {
	for (let freq in freqs)
		scan_trigger(wdev, freq, width);
}

function phy_get(wdev) {
	let res = nl.request(def.NL80211_CMD_GET_WIPHY, def.NLM_F_DUMP, { split_wiphy_dump: true });

	if (res === false)
		warn("Unable to lookup phys: " + nl.error() + "\n");

	return res;
}

function phy_get_frequencies(phy) {
	let freqs = [];

	for (let band in phy.wiphy_bands) {
		for (let freq in band?.freqs || [])
			if (!freq.disabled)
				push(freqs, freq.freq);
	}
	return freqs;
}

function phy_frequency_dfs(phy, curr) {
	let freqs = [];

	for (let band in phy.wiphy_bands) {
		for (let freq in band?.freqs || [])
			if (freq.freq == curr && freq.dfs_state >= 0)
				return true;
	}
	return false;
}

let phys = phy_get();
let ifaces = iface_get();

function intersect(list, filter) {
	let res = [];

	for (let item in list)
		if (index(filter, item) >= 0)
			push(res, item);
	return res;
}

function wifi_scan() {
	let scan = [];

	for (let phy in phys) {
		let iface = iface_find(phy.wiphy, [ IFTYPE_STATION, IFTYPE_AP ], ifaces);
		let scan_iface = false;
		if (!iface) {
			warn('no valid interface found for phy' + phy.wiphy + '\n');
			nl.request(def.NL80211_CMD_NEW_INTERFACE, 0, { wiphy: phy.wiphy, ifname: 'scan', iftype: IFTYPE_STATION });
			nl.waitfor([ def.NL80211_CMD_NEW_INTERFACE ], 1000);
			scan_iface = true;
			iface = {
				dev: 'scan',
				channel_width: 1,
			};
			rtnl.request(rtnl.const.RTM_NEWLINK, 0, { dev: 'scan', flags: IFF_UP, change: 1});
			sleep(1000);
		}

		printf("scanning on phy%d\n", phy.wiphy);

		let freqs = phy_get_frequencies(phy);
		if (length(intersect(freqs, frequency_list_2g)))
			scan_trigger(iface.dev, frequency_list_2g);

		let ch_width = iface.channel_width;
		if (frequency_width[bandwith])
			ch_width = frequency_width[bandwith];
		let freqs_5g = intersect(freqs, frequency_list_5g[ch_width]);
		if (length(freqs_5g)) {
			if (override_dfs && !scan_iface && phy_frequency_dfs(phy, iface.wiphy_freq)) {
				ctx.call(sprintf('hostapd.%s', iface.dev), 'switch_chan', { freq: 5180, bcn_count: 10 });
				sleep(2000)
			}
			trigger_scan_width(iface.dev, freqs_5g, ch_width);
		}
		let res = nl.request(def.NL80211_CMD_GET_SCAN, def.NLM_F_DUMP, { dev: iface.dev });
		for (let bss in res) {
			bss = bss.bss;
			let res = {
				bssid: bss.bssid,
				frequency: +bss.frequency,
				channel: frequency_to_channel(+bss.frequency),
				signal: +bss.signal_mbm / 100,
			};
			if (verbose) {
				res.tsf = +bss.tsf;
				res.last_seen = +bss.seen_ms_ago;
				res.capability = +bss.capability;
				res.ies = [];
			}


			for (let ie in bss.beacon_ies) {
				switch (ie.type) {
				case 0:
					res.ssid = ie.data;
					break;
				case 11:      
					res.sta_count = ord(ie.data, 1) * 256 + ord(ie.data, 0);
					res.ch_util = ord(ie.data, 2);                          
					break;   
				case 114:
					if (verbose)
						res.meshid = ie.data;
					break;
				case 0x3d:
					if (verbose)
						res.ht_oper = b64enc(ie.data);
					break;
				case 0xc0:
					if (verbose)
						res.vht_oper = b64enc(ie.data);
					break;
				case 0xdd:
					let oui = hexenc(substr(ie.data, 0, 3));
					let type = ord(ie.data, 3);
					let data = substr(ie.data, 4);
					switch (oui) {
					case '48d017':
						res.tip_oui = true;
						switch(type) {
						case 1:
							if (data)
								res.tip_serial = data;
							break;
						case 2:
							if (data)
								res.tip_name = data;
							break;
						case 3:
							if (data)
								res.tip_network_id = data;
							break;
						}
						break;
					}
					break;
				default:
					if (verbose)
						push(res.ies, { type: ie.type, data: b64enc(ie.data) });
					break;
				}
			}

			if (args.periodic && !args.information_elements)
				delete res.ies;
			push(scan, res);
		}
		if (scan_iface) {
			warn('removing temporary interface\n');
			nl.request(def.NL80211_CMD_DEL_INTERFACE, 0, { dev: 'scan' });
		}
	}
	printf("%.J\n", scan);
	return scan;
}

let scan = wifi_scan();

if (args.periodic) {
	ctx.call('ucentral', 'send', {
		method: 'wifiscan',
		params: { data: scan }
	});
	return;
}

result_json({
	error: 0,
	text: "Success",
	resultCode: 1,
	scan,
});
