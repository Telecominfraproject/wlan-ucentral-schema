import * as libubus from 'ubus';
import * as nl from 'nl80211';
let def = nl.const;
let scan =  [];

if (!args)
	args = {
		active: true,
		verbose: true,
		override_dfs: true,
		information_elements: true,
	};

let ubus = libubus.connect();

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

function override_dfs() {
	if (!args?.override_dfs)
		return;
	for (let obj in ubus.list()) {
		if (split(obj, '.')[0] != 'hostapd')
			continue;
		let status = ubus.call(obj, 'get_status');
		if (!status)
			continue;
		if (status.freq < 5180 || status.freq > 5960)
			continue;
		ubus.call(obj, 'switch_chan', { freq: 5180, bcn_count: 10 });
		sleep(5000);
		break;
	}
}

function trigger_scan() {
	for (let obj in ubus.list()) {
		let dev = split(obj, '.')[1];
		if (split(obj, '.')[0] != 'hostapd' || !dev)
			continue;
		system(`iw dev ${dev} scan ap-force ${args.active ? "ssid ''" : "passive"}`);
		printf('scan complete\n');

		let res = nl.request(def.NL80211_CMD_GET_SCAN, def.NLM_F_DUMP, { dev  });
		for (let bss in res) {
			bss = bss.bss;
			let res = {
				bssid: bss.bssid,
				frequency: +bss.frequency,
				channel: frequency_to_channel(+bss.frequency),
				signal: +bss.signal_mbm / 100,
			};
			if (args.verbose) {
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
					if (args.verbose)
						push(res.ies, { type: ie.type, data: b64enc(ie.data) });
					break;
				}
			}

			if (args.periodic && !args.information_elements)
				delete res.ies;
			push(scan, res);
		}
		return;
	}
}

override_dfs();
trigger_scan();

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
