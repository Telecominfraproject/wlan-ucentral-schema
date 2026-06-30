// mapping 5G to S1G(HaLow)
export function map5GToS1G() {
	// format: 5G channel -> { s1g_channel, s1g_freq, s1g_bw }
	let mappingTable = {
		// 1MHz bandwidth
		'132': { s1g_channel: 1, s1g_freq: 902, s1g_bw: 1 },
		'136': { s1g_channel: 3, s1g_freq: 903, s1g_bw: 1 },
		'36': { s1g_channel: 5, s1g_freq: 904, s1g_bw: 1 },
		'40': { s1g_channel: 7, s1g_freq: 905, s1g_bw: 1 },
		'44': { s1g_channel: 9, s1g_freq: 906, s1g_bw: 1 },
		'48': { s1g_channel: 11, s1g_freq: 907, s1g_bw: 1 },
		'52': { s1g_channel: 13, s1g_freq: 908, s1g_bw: 1 },
		'56': { s1g_channel: 15, s1g_freq: 909, s1g_bw: 1 },
		'60': { s1g_channel: 17, s1g_freq: 910, s1g_bw: 1 },
		'64': { s1g_channel: 19, s1g_freq: 911, s1g_bw: 1 },
		'100': { s1g_channel: 21, s1g_freq: 912, s1g_bw: 1 },
		'104': { s1g_channel: 23, s1g_freq: 913, s1g_bw: 1 },
		'108': { s1g_channel: 25, s1g_freq: 914, s1g_bw: 1 },
		'112': { s1g_channel: 27, s1g_freq: 915, s1g_bw: 1 },
		'116': { s1g_channel: 29, s1g_freq: 916, s1g_bw: 1 },
		'120': { s1g_channel: 31, s1g_freq: 917, s1g_bw: 1 },
		'124': { s1g_channel: 33, s1g_freq: 918, s1g_bw: 1 },
		'128': { s1g_channel: 35, s1g_freq: 919, s1g_bw: 1 },
		'149': { s1g_channel: 37, s1g_freq: 920, s1g_bw: 1 },
		'153': { s1g_channel: 39, s1g_freq: 921, s1g_bw: 1 },
		'157': { s1g_channel: 41, s1g_freq: 922, s1g_bw: 1 },
		'161': { s1g_channel: 43, s1g_freq: 923, s1g_bw: 1 },
		'165': { s1g_channel: 45, s1g_freq: 924, s1g_bw: 1 },
		'169': { s1g_channel: 47, s1g_freq: 925, s1g_bw: 1 },
		'173': { s1g_channel: 49, s1g_freq: 926, s1g_bw: 1 },
		'177': { s1g_channel: 51, s1g_freq: 927, s1g_bw: 1 },

		// 2MHz bandwidth
		'134': { s1g_channel: 2, s1g_freq: 903, s1g_bw: 2 },
		'38': { s1g_channel: 6, s1g_freq: 905, s1g_bw: 2 },
		'46': { s1g_channel: 10, s1g_freq: 907, s1g_bw: 2 },
		'54': { s1g_channel: 14, s1g_freq: 909, s1g_bw: 2 },
		'62': { s1g_channel: 18, s1g_freq: 911, s1g_bw: 2 },
		'102': { s1g_channel: 22, s1g_freq: 913, s1g_bw: 2 },
		'110': { s1g_channel: 26, s1g_freq: 915, s1g_bw: 2 },
		'118': { s1g_channel: 30, s1g_freq: 917, s1g_bw: 2 },
		'126': { s1g_channel: 34, s1g_freq: 919, s1g_bw: 2 },
		'151': { s1g_channel: 38, s1g_freq: 921, s1g_bw: 2 },
		'159': { s1g_channel: 42, s1g_freq: 923, s1g_bw: 2 },
		'167': { s1g_channel: 46, s1g_freq: 925, s1g_bw: 2 },
		'175': { s1g_channel: 50, s1g_freq: 927, s1g_bw: 2 },

		// 4MHz bandwidth
		'42': { s1g_channel: 8, s1g_freq: 906, s1g_bw: 4 },
		'58': { s1g_channel: 16, s1g_freq: 910, s1g_bw: 4 },
		'106': { s1g_channel: 24, s1g_freq: 914, s1g_bw: 4 },
		'122': { s1g_channel: 32, s1g_freq: 918, s1g_bw: 4 },
		'155': { s1g_channel: 40, s1g_freq: 922, s1g_bw: 4 },
		'171': { s1g_channel: 48, s1g_freq: 926, s1g_bw: 4 },

		// 8MHz bandwidth
		'50': { s1g_channel: 12, s1g_freq: 908, s1g_bw: 8 },
		'114': { s1g_channel: 28, s1g_freq: 916, s1g_bw: 8 },
		'163': { s1g_channel: 44, s1g_freq: 924, s1g_bw: 8 }
	};

	return mappingTable;
};

export function process_halow_radio(radio, survey_data) {
	// Check if this is a HaLow device
	if (index(radio.band, 'HaLow') == -1)
		return false;
	
	// Get mapping table
	let mapping_table = map5GToS1G();
	let orig_channels = radio.channels;
	let orig_frequency = radio.frequency;

	// Use the second channel in the list if available
	let selected_channel = null;
	let selected_channel_idx = -1;

	// Check if we have at least two channels in the list
	if (length(orig_channels) >= 2) {
		// Take the second channel
		selected_channel = '' + orig_channels[1]; // Convert to string
		selected_channel_idx = 1;
	} else {
		// Fallback to using the smallest channel if only one channel available
		for (let i = 0; i < length(orig_channels); i++) {
			let ch = '' + orig_channels[i]; // Convert to string
			if (mapping_table[ch] && (selected_channel === null || +ch < +selected_channel)) {
				selected_channel = ch;
				selected_channel_idx = i;
			}
		}
	}

	// If we found a valid channel to map
	if (selected_channel !== null && mapping_table[selected_channel]) {
		// Map to S1G
		let s1g_info = mapping_table[selected_channel];
		radio.channel = s1g_info.s1g_channel;

		// Set S1G bandwidth
		let bandwidth = s1g_info.s1g_bw;
		radio.channel_width = bandwidth;

		// Report channels[] and frequency[] aligned 1:1, same as 2G/5G.
		// 2G/5G push driver-reported channel/freq directly without collapsing,
		// so controller can map the operating channel to its center frequency.
		let center_freq = s1g_info.s1g_freq;

		if (bandwidth == 1) {
			// 1MHz: driver only reports one channel
			radio.frequency = [center_freq, center_freq];
			radio.channels = [s1g_info.s1g_channel, s1g_info.s1g_channel];
		} else {
			// 2/4/8MHz: map each orig channel to S1G channel+freq, keep
			// 1:1 aligned (do NOT uniq - same behaviour as 2G/5G).
			let s1g_channels = [];
			let s1g_frequencies = [];
			for (let i = 0; i < length(orig_channels); i++) {
				let ch = '' + orig_channels[i];
				if (mapping_table[ch]) {
					push(s1g_channels, mapping_table[ch].s1g_channel);
					push(s1g_frequencies, mapping_table[ch].s1g_freq);
				}
			}
			if (length(s1g_channels)) {
				radio.channels = s1g_channels;
				radio.frequency = s1g_frequencies;
			}
		}

		// Update survey frequencies to match the S1G center frequency in MHz
		let s1g_center_freq_khz = center_freq;

		// Collect survey items
		radio.survey = [];
		for (let k, v in survey_data.survey) {
			if (v.frequency in orig_frequency) {
				// Make a copy of the survey item and update frequency
				let survey_item = { ...v };
				survey_item.frequency = s1g_center_freq_khz;
				push(radio.survey, survey_item);
			}
		}
		
		return true;
	}
	
	return false;
};



// Convert the driver-reported (5G-borrowed) frequencies of a HaLow/S1G SSID
// into real S1G frequencies, mirroring the radio-level conversion done in
// process_halow_radio(). The morse driver tunes on 5GHz channels under the
// hood, so wif.channel/wif.frequency carry 5GHz values (e.g. 5560/5570).
// Without this remap the controller filters the SSID into the 5GHz band and the
// HaLow client information is not displayed.
export function process_halow_ssid_chan_info(ssid, wif) {
	// SSID band is uc(config.band); HaLow radios render band='s1g' -> 'S1G'.
	if (index(ssid.band, 'S1G') == -1)
		return false;

	let mapping_table = map5GToS1G();
	let orig_channels = wif.channel || [];

	// Pick the operating channel the same way as the radio path: prefer the
	// second channel (center freq), fall back to the smallest mappable one.
	let selected_channel = null;
	if (length(orig_channels) >= 2) {
		selected_channel = '' + orig_channels[1];
	} else {
		for (let i = 0; i < length(orig_channels); i++) {
			let ch = '' + orig_channels[i];
			if (mapping_table[ch] && (selected_channel === null || +ch < +selected_channel))
				selected_channel = ch;
		}
	}

	if (selected_channel === null || !mapping_table[selected_channel])
		return false;

	let s1g_info = mapping_table[selected_channel];
	let bandwidth = s1g_info.s1g_bw;
	let center_freq = s1g_info.s1g_freq;

	if (bandwidth == 1) {
		// 1MHz: driver only reports one channel, duplicate for UI
		ssid.frequency = [center_freq, center_freq];
	} else {
		// 2/4/8MHz: map each orig channel to its S1G freq, keep 1:1 aligned
		let s1g_frequencies = [];
		for (let i = 0; i < length(orig_channels); i++) {
			let ch = '' + orig_channels[i];
			if (mapping_table[ch])
				push(s1g_frequencies, mapping_table[ch].s1g_freq);
		}
		if (length(s1g_frequencies))
			ssid.frequency = s1g_frequencies;
	}

	return true;
};
