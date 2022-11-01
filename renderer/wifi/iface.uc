let nl = require("nl80211");
let def = nl.const;

const NL80211_IFTYPE_STATION = 2;
const NL80211_IFTYPE_AP = 3;
const NL80211_IFTYPE_MESH_POINT = 7;
let iftypes = {
	[NL80211_IFTYPE_STATION]: "station",
	[NL80211_IFTYPE_AP]: "ap",
	[NL80211_IFTYPE_MESH_POINT]: "mesh",
};

const NL80211_CHAN_WIDTH_20 = 1;
const NL80211_CHAN_WIDTH_40 = 2;
const NL80211_CHAN_WIDTH_80 = 3;
const NL80211_CHAN_WIDTH_80P80 = 4;
const NL80211_CHAN_WIDTH_160 = 5;
const NL80211_CHAN_WIDTH_5 = 6;
const NL80211_CHAN_WIDTH_10 = 7;
let chwidth = {
	[NL80211_CHAN_WIDTH_20]: "20",
	[NL80211_CHAN_WIDTH_40]: "40",
	[NL80211_CHAN_WIDTH_80]: "80",
	[NL80211_CHAN_WIDTH_80P80]: "80p80",
	[NL80211_CHAN_WIDTH_160]: "160",
	[NL80211_CHAN_WIDTH_5]: "5",
	[NL80211_CHAN_WIDTH_10]: "10",
};

function freq2channel(freq) {
	if (freq == 2484)
		return 14;
	else if (freq < 2484)
		return (freq - 2407) / 5;
	else if (freq >= 4910 && freq <= 4980)
		return (freq - 4000) / 5;
	else if(freq >= 56160 + 2160 * 1 && freq <= 56160 + 2160 * 6)
		return (freq - 56160) / 2160;
	else if (freq >= 5955 && freq <= 7115)
		return (freq - 5950) / 5;
	else
		return (freq - 5000) / 5;
}

function wif_get(wdev) {
        let res = nl.request(def.NL80211_CMD_GET_INTERFACE, def.NLM_F_DUMP);

        if (res === false)
                warn("Unable to lookup interfaces: " + nl.error() + "\n");

        return res;
}

function lookup_wifs() {
	let wifs = wif_get();
	let rv = {};
	for (let wif in wifs) {
		if (!wif.wiphy_freq || !iftypes[wif.iftype])
			continue;
		let w = {};
		w.ssid = wif.ssid;
		w.bssid = wif.mac;
		w.mode = iftypes[wif.iftype];
		w.channel = [];
		w.frequency = [];
		w.tx_power = (wif.wiphy_tx_power_level / 100) || 0;
		for (let f in [ wif.wiphy_freq, wif.center_freq1, wif.center_freq2 ])
			if (f) {
				push(w.channel, freq2channel(f));
				push(w.frequency, f);
			}
		if (chwidth[wif.channel_width])
			w.ch_width = chwidth[wif.channel_width];
		rv[wif.ifname] = w;
	}
	return rv;
}

return lookup_wifs();
