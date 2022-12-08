let nl = require("nl80211");
let def = nl.const;


function parse_bitrate(info) {
	let rate = {
		bitrate: (info.bitrate32 || info.bitrate) * 100
	};

	if (info.short_gi)
		rate.sgi = true;

	if (info.mcs) {
		rate.ht = true;
		rate.mcs = info.mcs;
	}
	else if (info.vht_mcs) {
		rate.vht = true;
		rate.mcs = info.vht_mcs;
		rate.nss = info.vht_nss;
	}
	else if (info.he_mcs) {
		rate.he = true;
		rate.mcs = info.he_mcs;
		rate.nss = info.he_nss;
		rate.he_gi = info.he_gi;
		rate.he_dcm = info.he_dcm;
	}

	if (info.width_40)
		rate.chwidth = 40;
	else if (info.width_80)
		rate.chwidth = 80;
	else if (info.width_80p80)
		rate.chwidth = 8080;
	else if (info.width_160)
		rate.chwidth = 160;
	else if (info.width_10)
		rate.chwidth = 10;
	else if (info.width_5)
		rate.chwidth = 5;
	else
		rate.chwidth = 20;
	return rate;
}

function iface_assoclist(wif) {
	let params = { dev: wif.ifname };
	let res = nl.request(def.NL80211_CMD_GET_STATION, def.NLM_F_DUMP, params);

	if (res === false) {
		warn("Unable to lookup associations: " + nl.error() + "\n");
		return [];
	}
	let assocdev = [];
	for (let sta in res) {
		let assoc = {
			bssid: wif.mac,
			station: sta.mac,
			connected: +sta.sta_info?.connected_time,
			inactive: +sta.sta_info?.inactive_time / 1000,
			tx_duration: +sta.sta_info?.tx_duration,
			rx_duration: +sta.sta_info?.rx_duration,
			rssi: +sta.sta_info?.signal,
			ack_signal: +sta.sta_info?.ack_signal,
			ack_signal_avg: +sta.sta_info?.ack_signal_avg,
			rx_packets: +sta.sta_info?.rx_packets,
			tx_packets: +sta.sta_info?.tx_packets,
			rx_bytes: +sta.sta_info?.rx_bytes64,
			tx_bytes: +sta.sta_info?.tx_bytes64,
			tx_retries: +sta.sta_info?.tx_retries,
			tx_failed: +sta.sta_info?.tx_failed,
			rx_rate: parse_bitrate(sta.sta_info?.rx_bitrate || {}),
			tx_rate: parse_bitrate(sta.sta_info?.tx_bitrate || {}),
		};
		if (global.tid_stats)
			assoc.tid_stats = sta.sta_info?.tid_stats || [];
		push(assocdev, assoc);
	};
	return assocdev;
}

function wif_get(wdev) {
        let res = nl.request(def.NL80211_CMD_GET_INTERFACE, def.NLM_F_DUMP);

        if (res === false)
                warn("Unable to lookup interfaces: " + nl.error() + "\n");

        return res;
}

function lookup_stations() {
	let rv = {};
	let wifs = wif_get();
	for (let wif in wifs) {
		let assoc = iface_assoclist(wif);
		if (length(assoc))
			rv[wif.ifname] = assoc;
	}
	return rv;
}

return lookup_stations();
