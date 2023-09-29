let fs = require('fs');
let uci = require("uci");
let cursor = uci ? uci.cursor() : null;
let nl = require("nl80211");
let def = nl.const;

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

function phy_get(wdev) {
        let res = nl.request(def.NL80211_CMD_GET_WIPHY, def.NLM_F_DUMP, { split_wiphy_dump: true });

        if (res === false)
                warn("Unable to lookup phys: " + nl.error() + "\n");

        return res;
}

let paths = {};

function add_path(path, phy, index) {
	if (!phy)
		return;
	phy = fs.basename(phy);
	paths[phy] = path;
	if (index)
		paths[phy] += '+' + index;
}

function lookup_paths() {
	let wireless = cursor.get_all('wireless');
	for (let k, section in wireless) {
		if (section['.type'] != 'wifi-device' || !section.path)
			continue;
		let phys = fs.glob(sprintf('/sys/devices/%s/ieee80211/phy*', section.path));
		if (!length(phys))
			phys = fs.glob(sprintf('/sys/devices/platform/%s/ieee80211/phy*', section.path));
		if (!length(phys))
			continue;
		sort(phys);
		let index = 0;
		for (let phy in phys)
			add_path(section.path, phy, index++);
	}
}

function get_hwmon(phy) {
	let hwmon = fs.glob(sprintf('/sys/class/ieee80211/%s/hwmon*/temp*_input', phy));
	if (!hwmon)
		return 0;
	let file = fs.open(hwmon[0], 'r');
	if (!file)
		return 0;
	let temp = +file.read('all');
	file.close();
	return temp;
}

function lookup_phys() {
	lookup_paths();

	let phys = phy_get();
	let ret = {};
	for (let phy in phys) {
		let phyname = 'phy' + phy.wiphy;
		let path = paths[phyname];
		if (!path)
			continue;

		let p = {};
		let temp = get_hwmon('phy' + phy.wiphy);
		if (temp)
			p.temperature = temp / 1000;

		p.tx_ant = phy.wiphy_antenna_tx;
		p.rx_ant = phy.wiphy_antenna_rx;
		p.tx_ant_avail = phy.wiphy_antenna_avail_tx;
		p.rx_ant_avail = phy.wiphy_antenna_avail_rx;
		p.frequencies = [];
		p.channels = [];
		p.dfs_channels = [];
		p.htmode = [];
		p.band = [];
		for (let band in phy.wiphy_bands) {
			for (let freq in band?.freqs) {
				if (freq.disabled)
					continue;
				push(p.frequencies, freq.freq);
				push(p.channels, freq2channel(freq.freq));
				if (freq.radar)
					push(p.dfs_channels, freq2channel(freq.freq));
				if (freq.freq >= 6000)
					push(p.band, '6G');
				else if (freq.freq <= 2484)
					push(p.band, '2G');
				else if (freq.freq >= 5160 && freq.freq <= 5885)
					push(p.band, '5G');
			}
			if (band?.ht_capa) {
				p.ht_capa = band.ht_capa;
				push(p.htmode, 'HT20');
				if (band.ht_capa & 0x2)
					push(p.htmode, 'HT40');
			}
			if (band?.vht_capa) {
				p.vht_capa = band.vht_capa;
				push(p.htmode, 'VHT20', 'VHT40', 'VHT80');
				let chwidth = (band?.vht_capa >> 2) & 0x3;
				switch(chwidth) {
				case 2:
					push(p.htmode, 'VHT80+80');
					/* fall through */
				case 1:
					push(p.htmode, 'VHT160');
				}
			}
			for (let iftype in band?.iftype_data) {
				if (iftype.iftypes?.ap) {
					p.he_phy_capa = iftype?.he_cap_phy;
					p.he_mac_capa = iftype?.he_cap_mac;
					push(p.htmode, 'HE20');
					let chwidth = (iftype?.he_cap_phy[0] || 0) & 0xff;
					if (chwidth & 0x2 || chwidth & 0x4)
						push(p.htmode, 'HE40');
					if (chwidth & 0x4)
						push(p.htmode, 'HE80');
					if (chwidth & 0x8 || chwidth & 0x10)
						push(p.htmode, 'HE160');
					if (chwidth & 0x10)
						push(p.htmode, 'HE80+80');
					if (iftype.eht_cap_phy) {
						p.eht_phy_capa = iftype?.eht_cap_phy;
						p.eht_mac_capa = iftype?.eht_cap_mac;
						push(p.htmode, 'EHT20');
						if (chwidth & 0x2 || chwidth & 0x4)
							push(p.htmode, 'EHT40');
						if (chwidth & 0x4)
							push(p.htmode, 'EHT80');
						if (chwidth & 0x8 || chwidth & 0x10)
							push(p.htmode, 'EHT160');
						if (chwidth & 0x10)
							push(p.htmode, 'EHT80+80');
                                                if ('6G' in p.band)
                                                        push(p.htmode, 'EHT320');
					}
				}
			}
		}

		p.band = uniq(p.band);
		if (!length(p.dfs_channels))
			delete p.dfs_channels;
		ret[path] = p;
	}
	return ret;
}

return lookup_phys();
