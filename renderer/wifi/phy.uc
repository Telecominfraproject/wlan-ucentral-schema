let fs = require('fs');
let uci = require("uci");
let cursor = uci ? uci.cursor() : null;
let nl = require("nl80211");
let def = nl.const;

function freq2channel(freq) {
	if (freq == 2484)
		return 14;
	else if (freq < 1000)
		return (freq - 900) / 2;
	else if (freq > 2400 && freq < 2484)
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

function lookup_board() {
	let board = fs.readfile('/etc/board.json');
	if (board)
		board = json(board);
	if (!length(board?.wlan))
		return null;
	let ret = {};
	for (let name, phy in board?.wlan) {
		if (!length(phy.info?.radios))
			continue;
		for (let band, data in phy.info.bands) {
			let radio_index = -1;
			let channels = [];
			let frequencies = [];
			for (let radio in phy.info.radios)
				if (radio.bands[band]) {
					radio_index = radio.index;
					frequencies = radio.bands[band].frequencies;
					channels = radio.bands[band].channels;
				}

			ret[`${phy.path}:${band}`] = {
				tx_ant: phy.info.antenna_tx,
				rx_ant: phy.info.antenna_rx,
				tx_ant_avail: phy.info.antenna_tx,
				rx_ant_avail: phy.info.antenna_rx,
				no_reconf: true,
				htmode: data.modes,
				band: [ band ],
				radio_index,
				frequencies,
				channels,
			};
		}
		return ret;
	}
	return null;
}   

// mapping 5G to S1G(HaLow)
function map5GToS1G() {
    // format: 5G channel -> { s1g_channel, s1g_freq }
    let mappingTable = {
        // 1MHz bandwidth
        '132': { s1g_channel: 1, s1g_freq: 902 },
        '136': { s1g_channel: 3, s1g_freq: 903 },
        '36': { s1g_channel: 5, s1g_freq: 904 },
        '40': { s1g_channel: 7, s1g_freq: 905 },
        '44': { s1g_channel: 9, s1g_freq: 906 },
        '48': { s1g_channel: 11, s1g_freq: 907 },
        '52': { s1g_channel: 13, s1g_freq: 908 },
        '56': { s1g_channel: 15, s1g_freq: 909 },
        '60': { s1g_channel: 17, s1g_freq: 910 },
        '64': { s1g_channel: 19, s1g_freq: 911 },
        '100': { s1g_channel: 21, s1g_freq: 912 },
        '104': { s1g_channel: 23, s1g_freq: 913 },
        '108': { s1g_channel: 25, s1g_freq: 914 },
        '112': { s1g_channel: 27, s1g_freq: 915 },
        '116': { s1g_channel: 29, s1g_freq: 916 },
        '120': { s1g_channel: 31, s1g_freq: 917 },
        '124': { s1g_channel: 33, s1g_freq: 918 },
        '128': { s1g_channel: 35, s1g_freq: 919 },
        '149': { s1g_channel: 37, s1g_freq: 920 },
        '153': { s1g_channel: 39, s1g_freq: 921 },
        '157': { s1g_channel: 41, s1g_freq: 922 },
        '161': { s1g_channel: 43, s1g_freq: 923 },
        '165': { s1g_channel: 45, s1g_freq: 924 },
        '169': { s1g_channel: 47, s1g_freq: 925 },
        '173': { s1g_channel: 49, s1g_freq: 926 },
        '177': { s1g_channel: 51, s1g_freq: 927 },
         // 2MHz bandwidth
        '134': { s1g_channel: 2, s1g_freq: 903 },
        '38': { s1g_channel: 6, s1g_freq: 905 },
        '46': { s1g_channel: 10, s1g_freq: 907 },
        '54': { s1g_channel: 14, s1g_freq: 909 },
        '62': { s1g_channel: 18, s1g_freq: 911 },
        '102': { s1g_channel: 22, s1g_freq: 913 },
        '110': { s1g_channel: 26, s1g_freq: 915 },
        '118': { s1g_channel: 30, s1g_freq: 917 },
        '126': { s1g_channel: 34, s1g_freq: 919 },
        '151': { s1g_channel: 38, s1g_freq: 921 },
        '159': { s1g_channel: 42, s1g_freq: 923 },
        '167': { s1g_channel: 46, s1g_freq: 925 },
        '175': { s1g_channel: 50, s1g_freq: 927 },
        // 4MHz bandwidth
        '42': { s1g_channel: 8, s1g_freq: 906 },
        '58': { s1g_channel: 16, s1g_freq: 910 },
        '106': { s1g_channel: 24, s1g_freq: 914 },
        '122': { s1g_channel: 32, s1g_freq: 918 },
        '155': { s1g_channel: 40, s1g_freq: 922 },
        '171': { s1g_channel: 48, s1g_freq: 926 },
        // 8MHz bandwidth
        '50': { s1g_channel: 12, s1g_freq: 908 },
        '114': { s1g_channel: 28, s1g_freq: 916 },
        '163': { s1g_channel: 44, s1g_freq: 924 }
    };

    return mappingTable;
}

function lookup_phys() {
	let ret = lookup_board();
	if (ret)
		return ret;
	lookup_paths();

	let phys = phy_get();
	ret = {};

	// get 5G to S1G mapping table
	let s1gMapping = map5GToS1G();

	for (let phy in phys) {
		if (!phy || !phy.wiphy)
			continue;
		let phyname = 'phy' + phy.wiphy;
		let path = paths[phyname];
		if (!path)
			continue;

		// check whether MORSE PHY
		let isMorse = false;
		let morsePath = '/sys/kernel/debug/ieee80211/' + phyname + '/morse';

		// check whether MORSE dir exists
		if (fs.stat(morsePath))
			isMorse = true;

		let p = {};

		p.is_morse_phy = isMorse;  // save result in is_morse_phy

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

				let channel = freq2channel(freq.freq);
				// if MORSE PHY and band is 5G，mapping to S1G
				if (isMorse && freq.freq >= 5160 && freq.freq <= 5885) {
					let ch = "" + channel;
					if (ch in s1gMapping) {
						// replace 5G ch into S1G ch
						channel = s1gMapping[ch].s1g_channel;
						push(p.channels, channel);
						push(p.frequencies, s1gMapping[ch].s1g_freq);
					} else {
						// no S1G ch in table, keep 5G ch
						push(p.channels, channel);
						push(p.frequencies, freq.freq);
					}
				} else {
					// not MORSE PHY or not 5G
					push(p.channels, channel);
					push(p.frequencies, freq.freq);
					if (freq.radar)
						push(p.dfs_channels, channel);
				}

				if (freq.freq >= 6000)
					push(p.band, '6G');
				else if (freq.freq <= 2484 && freq.freq > 2400)
					push(p.band, '2G');
				else if (freq.freq >= 5160 && freq.freq <= 5885 && !isMorse)
					push(p.band, '5G');
				else if (freq.freq < 1000 || (isMorse && freq.freq >= 5160 && freq.freq <= 5885))
					push(p.band, 'HaLow');
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
	for (let path in ret) {
		system("logger 'phy: PHY path:" + path + ", bands:" + join(',', ret[path].band) + "'");
	}
	return ret;
}

return lookup_phys();
