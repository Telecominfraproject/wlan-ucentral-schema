// HaLow (802.11ah / S1G) per-country channel map + lookup API.
// Maps a HaLow country to its valid S1G channels, operating class and
// centre frequency. Data table followed by the lookup helpers below.

"use strict";

const CHANNEL_MAP = {
	"AU": {
		country_name: "Australia",
		channels: {
			"28": { country_code: "AU", bw: 1, s1g_chan: 28, s1g_op_class: 22, global_op_class: 50, centre_freq_mhz: 916, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Australia", tx_power_max: 30, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 36 },
			"30": { country_code: "AU", bw: 1, s1g_chan: 30, s1g_op_class: 22, global_op_class: 50, centre_freq_mhz: 917, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Australia", tx_power_max: 30, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 40 },
			"32": { country_code: "AU", bw: 1, s1g_chan: 32, s1g_op_class: 22, global_op_class: 50, centre_freq_mhz: 918, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Australia", tx_power_max: 30, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 44 },
			"34": { country_code: "AU", bw: 1, s1g_chan: 34, s1g_op_class: 22, global_op_class: 50, centre_freq_mhz: 919, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Australia", tx_power_max: 30, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 48 },
			"36": { country_code: "AU", bw: 1, s1g_chan: 36, s1g_op_class: 22, global_op_class: 50, centre_freq_mhz: 920, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Australia", tx_power_max: 30, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 52 },
			"38": { country_code: "AU", bw: 1, s1g_chan: 38, s1g_op_class: 22, global_op_class: 50, centre_freq_mhz: 921, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Australia", tx_power_max: 30, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 56 },
			"40": { country_code: "AU", bw: 1, s1g_chan: 40, s1g_op_class: 22, global_op_class: 50, centre_freq_mhz: 922, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Australia", tx_power_max: 30, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 60 },
			"42": { country_code: "AU", bw: 1, s1g_chan: 42, s1g_op_class: 22, global_op_class: 50, centre_freq_mhz: 923, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Australia", tx_power_max: 30, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 64 },
			"44": { country_code: "AU", bw: 1, s1g_chan: 44, s1g_op_class: 22, global_op_class: 50, centre_freq_mhz: 924, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Australia", tx_power_max: 30, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 116 },
			"46": { country_code: "AU", bw: 1, s1g_chan: 46, s1g_op_class: 22, global_op_class: 50, centre_freq_mhz: 925, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Australia", tx_power_max: 30, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 120 },
			"48": { country_code: "AU", bw: 1, s1g_chan: 48, s1g_op_class: 22, global_op_class: 50, centre_freq_mhz: 926, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Australia", tx_power_max: 30, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 124 },
			"50": { country_code: "AU", bw: 1, s1g_chan: 50, s1g_op_class: 22, global_op_class: 50, centre_freq_mhz: 927, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Australia", tx_power_max: 30, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 128 },
			"29": { country_code: "AU", bw: 2, s1g_chan: 29, s1g_op_class: 23, global_op_class: 51, centre_freq_mhz: 916.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Australia", tx_power_max: 30, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 38 },
			"33": { country_code: "AU", bw: 2, s1g_chan: 33, s1g_op_class: 23, global_op_class: 51, centre_freq_mhz: 918.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Australia", tx_power_max: 30, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 46 },
			"37": { country_code: "AU", bw: 2, s1g_chan: 37, s1g_op_class: 23, global_op_class: 51, centre_freq_mhz: 920.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Australia", tx_power_max: 30, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 54 },
			"41": { country_code: "AU", bw: 2, s1g_chan: 41, s1g_op_class: 23, global_op_class: 51, centre_freq_mhz: 922.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Australia", tx_power_max: 30, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 62 },
			"45": { country_code: "AU", bw: 2, s1g_chan: 45, s1g_op_class: 23, global_op_class: 51, centre_freq_mhz: 924.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Australia", tx_power_max: 30, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 118 },
			"49": { country_code: "AU", bw: 2, s1g_chan: 49, s1g_op_class: 23, global_op_class: 51, centre_freq_mhz: 926.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Australia", tx_power_max: 30, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 126 },
			"31": { country_code: "AU", bw: 4, s1g_chan: 31, s1g_op_class: 24, global_op_class: 52, centre_freq_mhz: 917.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Australia", tx_power_max: 30, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 42 },
			"39": { country_code: "AU", bw: 4, s1g_chan: 39, s1g_op_class: 24, global_op_class: 52, centre_freq_mhz: 921.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Australia", tx_power_max: 30, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 58 },
			"47": { country_code: "AU", bw: 4, s1g_chan: 47, s1g_op_class: 24, global_op_class: 52, centre_freq_mhz: 925.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Australia", tx_power_max: 30, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 122 },
			"35": { country_code: "AU", bw: 8, s1g_chan: 35, s1g_op_class: 25, global_op_class: 53, centre_freq_mhz: 919.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Australia", tx_power_max: 30, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 50 },
			"43": { country_code: "AU", bw: 8, s1g_chan: 43, s1g_op_class: 25, global_op_class: 53, centre_freq_mhz: 923.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Australia", tx_power_max: 30, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 114 },
		},
		valid_channels: [ 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50 ],
		default_channel: 35
	},
	"CA": {
		country_name: "Canada",
		channels: {
			"3": { country_code: "CA", bw: 1, s1g_chan: 3, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 903.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Canada", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 136 },
			"5": { country_code: "CA", bw: 1, s1g_chan: 5, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 904.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Canada", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 36 },
			"7": { country_code: "CA", bw: 1, s1g_chan: 7, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 905.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Canada", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 40 },
			"9": { country_code: "CA", bw: 1, s1g_chan: 9, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 906.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Canada", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 44 },
			"11": { country_code: "CA", bw: 1, s1g_chan: 11, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 907.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Canada", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 48 },
			"13": { country_code: "CA", bw: 1, s1g_chan: 13, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 908.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Canada", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 52 },
			"15": { country_code: "CA", bw: 1, s1g_chan: 15, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 909.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Canada", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 56 },
			"17": { country_code: "CA", bw: 1, s1g_chan: 17, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 910.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Canada", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 60 },
			"19": { country_code: "CA", bw: 1, s1g_chan: 19, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 911.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Canada", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 64 },
			"21": { country_code: "CA", bw: 1, s1g_chan: 21, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 912.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Canada", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 100 },
			"23": { country_code: "CA", bw: 1, s1g_chan: 23, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 913.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Canada", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 104 },
			"25": { country_code: "CA", bw: 1, s1g_chan: 25, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 914.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Canada", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 108 },
			"27": { country_code: "CA", bw: 1, s1g_chan: 27, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 915.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Canada", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 112 },
			"29": { country_code: "CA", bw: 1, s1g_chan: 29, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 916.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Canada", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 116 },
			"31": { country_code: "CA", bw: 1, s1g_chan: 31, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 917.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Canada", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 120 },
			"33": { country_code: "CA", bw: 1, s1g_chan: 33, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 918.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Canada", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 124 },
			"35": { country_code: "CA", bw: 1, s1g_chan: 35, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 919.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Canada", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 128 },
			"37": { country_code: "CA", bw: 1, s1g_chan: 37, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 920.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Canada", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 149 },
			"39": { country_code: "CA", bw: 1, s1g_chan: 39, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 921.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Canada", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 153 },
			"41": { country_code: "CA", bw: 1, s1g_chan: 41, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 922.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Canada", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 157 },
			"43": { country_code: "CA", bw: 1, s1g_chan: 43, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 923.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Canada", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 161 },
			"45": { country_code: "CA", bw: 1, s1g_chan: 45, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 924.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Canada", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 165 },
			"47": { country_code: "CA", bw: 1, s1g_chan: 47, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 925.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Canada", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 169 },
			"49": { country_code: "CA", bw: 1, s1g_chan: 49, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 926.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Canada", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 173 },
			"6": { country_code: "CA", bw: 2, s1g_chan: 6, s1g_op_class: 2, global_op_class: 69, centre_freq_mhz: 905, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Canada", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 38 },
			"10": { country_code: "CA", bw: 2, s1g_chan: 10, s1g_op_class: 2, global_op_class: 69, centre_freq_mhz: 907, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Canada", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 46 },
			"14": { country_code: "CA", bw: 2, s1g_chan: 14, s1g_op_class: 2, global_op_class: 69, centre_freq_mhz: 909, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Canada", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 54 },
			"18": { country_code: "CA", bw: 2, s1g_chan: 18, s1g_op_class: 2, global_op_class: 69, centre_freq_mhz: 911, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Canada", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 62 },
			"22": { country_code: "CA", bw: 2, s1g_chan: 22, s1g_op_class: 2, global_op_class: 69, centre_freq_mhz: 913, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Canada", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 102 },
			"26": { country_code: "CA", bw: 2, s1g_chan: 26, s1g_op_class: 2, global_op_class: 69, centre_freq_mhz: 915, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Canada", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 110 },
			"30": { country_code: "CA", bw: 2, s1g_chan: 30, s1g_op_class: 2, global_op_class: 69, centre_freq_mhz: 917, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Canada", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 118 },
			"34": { country_code: "CA", bw: 2, s1g_chan: 34, s1g_op_class: 2, global_op_class: 69, centre_freq_mhz: 919, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Canada", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 126 },
			"38": { country_code: "CA", bw: 2, s1g_chan: 38, s1g_op_class: 2, global_op_class: 69, centre_freq_mhz: 921, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Canada", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 151 },
			"42": { country_code: "CA", bw: 2, s1g_chan: 42, s1g_op_class: 2, global_op_class: 69, centre_freq_mhz: 923, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Canada", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 159 },
			"46": { country_code: "CA", bw: 2, s1g_chan: 46, s1g_op_class: 2, global_op_class: 69, centre_freq_mhz: 925, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Canada", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 167 },
			"8": { country_code: "CA", bw: 4, s1g_chan: 8, s1g_op_class: 3, global_op_class: 70, centre_freq_mhz: 906, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Canada", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 42 },
			"16": { country_code: "CA", bw: 4, s1g_chan: 16, s1g_op_class: 3, global_op_class: 70, centre_freq_mhz: 910, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Canada", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 58 },
			"24": { country_code: "CA", bw: 4, s1g_chan: 24, s1g_op_class: 3, global_op_class: 70, centre_freq_mhz: 914, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Canada", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 106 },
			"32": { country_code: "CA", bw: 4, s1g_chan: 32, s1g_op_class: 3, global_op_class: 70, centre_freq_mhz: 918, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Canada", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 122 },
			"40": { country_code: "CA", bw: 4, s1g_chan: 40, s1g_op_class: 3, global_op_class: 70, centre_freq_mhz: 922, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Canada", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 155 },
			"12": { country_code: "CA", bw: 8, s1g_chan: 12, s1g_op_class: 4, global_op_class: 71, centre_freq_mhz: 908, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Canada", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 50 },
			"28": { country_code: "CA", bw: 8, s1g_chan: 28, s1g_op_class: 4, global_op_class: 71, centre_freq_mhz: 916, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Canada", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 114 },
			"44": { country_code: "CA", bw: 8, s1g_chan: 44, s1g_op_class: 4, global_op_class: 71, centre_freq_mhz: 924, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "Canada", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 163 },
		},
		valid_channels: [ 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 49 ],
		default_channel: 12
	},
	"EU": {
		country_name: "European Union",
		channels: {
			"1": { country_code: "EU", bw: 1, s1g_chan: 1, s1g_op_class: 6, global_op_class: 66, centre_freq_mhz: 863.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "User assigned EU", tx_power_max: 16.13, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 132 },
			"3": { country_code: "EU", bw: 1, s1g_chan: 3, s1g_op_class: 6, global_op_class: 66, centre_freq_mhz: 864.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "User assigned EU", tx_power_max: 16.13, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 136 },
			"5": { country_code: "EU", bw: 1, s1g_chan: 5, s1g_op_class: 6, global_op_class: 66, centre_freq_mhz: 865.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "User assigned EU", tx_power_max: 16.13, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 36 },
			"7": { country_code: "EU", bw: 1, s1g_chan: 7, s1g_op_class: 6, global_op_class: 66, centre_freq_mhz: 866.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "User assigned EU", tx_power_max: 16.13, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 40 },
			"9": { country_code: "EU", bw: 1, s1g_chan: 9, s1g_op_class: 6, global_op_class: 66, centre_freq_mhz: 867.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "User assigned EU", tx_power_max: 16.13, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 44 },
			"2": { country_code: "EU", bw: 2, s1g_chan: 2, s1g_op_class: 7, global_op_class: 67, centre_freq_mhz: 864, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "User assigned EU", tx_power_max: 16.13, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 134 },
			"6": { country_code: "EU", bw: 2, s1g_chan: 6, s1g_op_class: 7, global_op_class: 67, centre_freq_mhz: 866, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "User assigned EU", tx_power_max: 16.13, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 38 },
		},
		valid_channels: [ 1, 2, 3, 5, 6, 7, 9 ],
		default_channel: 2
	},
	"JP": {
		country_name: "Japan",
		channels: {
			"13": { country_code: "JP", bw: 1, s1g_chan: 13, s1g_op_class: 8, global_op_class: 73, centre_freq_mhz: 923, duty_cycle_ap: 10, duty_cycle_sta: 10, country: "Japan", tx_power_max: 16, duty_cycle_omit_ctrl_resp: true, pkt_spacing_ms: 2, airtime_min_ms: 2, airtime_max_ms: 100, map_5g_chan: 36 },
			"15": { country_code: "JP", bw: 1, s1g_chan: 15, s1g_op_class: 8, global_op_class: 73, centre_freq_mhz: 924, duty_cycle_ap: 10, duty_cycle_sta: 10, country: "Japan", tx_power_max: 16, duty_cycle_omit_ctrl_resp: true, pkt_spacing_ms: 2, airtime_min_ms: 2, airtime_max_ms: 100, map_5g_chan: 40 },
			"17": { country_code: "JP", bw: 1, s1g_chan: 17, s1g_op_class: 8, global_op_class: 73, centre_freq_mhz: 925, duty_cycle_ap: 10, duty_cycle_sta: 10, country: "Japan", tx_power_max: 16, duty_cycle_omit_ctrl_resp: true, pkt_spacing_ms: 2, airtime_min_ms: 2, airtime_max_ms: 100, map_5g_chan: 44 },
			"19": { country_code: "JP", bw: 1, s1g_chan: 19, s1g_op_class: 8, global_op_class: 73, centre_freq_mhz: 926, duty_cycle_ap: 10, duty_cycle_sta: 10, country: "Japan", tx_power_max: 16, duty_cycle_omit_ctrl_resp: true, pkt_spacing_ms: 2, airtime_min_ms: 2, airtime_max_ms: 100, map_5g_chan: 48 },
			"21": { country_code: "JP", bw: 1, s1g_chan: 21, s1g_op_class: 8, global_op_class: 73, centre_freq_mhz: 927, duty_cycle_ap: 10, duty_cycle_sta: 10, country: "Japan", tx_power_max: 16, duty_cycle_omit_ctrl_resp: true, pkt_spacing_ms: 2, airtime_min_ms: 2, airtime_max_ms: 100, map_5g_chan: 64 },
			"2": { country_code: "JP", bw: 2, s1g_chan: 2, s1g_op_class: 9, global_op_class: 64, centre_freq_mhz: 923.5, duty_cycle_ap: 10, duty_cycle_sta: 10, country: "Japan", tx_power_max: 16, duty_cycle_omit_ctrl_resp: true, pkt_spacing_ms: 2, airtime_min_ms: 2, airtime_max_ms: 100, map_5g_chan: 38 },
			"4": { country_code: "JP", bw: 2, s1g_chan: 4, s1g_op_class: 10, global_op_class: 64, centre_freq_mhz: 924.5, duty_cycle_ap: 10, duty_cycle_sta: 10, country: "Japan", tx_power_max: 16, duty_cycle_omit_ctrl_resp: true, pkt_spacing_ms: 2, airtime_min_ms: 2, airtime_max_ms: 100, map_5g_chan: 54 },
			"6": { country_code: "JP", bw: 2, s1g_chan: 6, s1g_op_class: 9, global_op_class: 64, centre_freq_mhz: 925.5, duty_cycle_ap: 10, duty_cycle_sta: 10, country: "Japan", tx_power_max: 16, duty_cycle_omit_ctrl_resp: true, pkt_spacing_ms: 2, airtime_min_ms: 2, airtime_max_ms: 100, map_5g_chan: 46 },
			"8": { country_code: "JP", bw: 2, s1g_chan: 8, s1g_op_class: 10, global_op_class: 64, centre_freq_mhz: 926.5, duty_cycle_ap: 10, duty_cycle_sta: 10, country: "Japan", tx_power_max: 16, duty_cycle_omit_ctrl_resp: true, pkt_spacing_ms: 2, airtime_min_ms: 2, airtime_max_ms: 100, map_5g_chan: 62 },
			"36": { country_code: "JP", bw: 4, s1g_chan: 36, s1g_op_class: 11, global_op_class: 65, centre_freq_mhz: 924.5, duty_cycle_ap: 10, duty_cycle_sta: 10, country: "Japan", tx_power_max: 16, duty_cycle_omit_ctrl_resp: true, pkt_spacing_ms: 2, airtime_min_ms: 2, airtime_max_ms: 100, map_5g_chan: 42 },
			"38": { country_code: "JP", bw: 4, s1g_chan: 38, s1g_op_class: 12, global_op_class: 65, centre_freq_mhz: 925.5, duty_cycle_ap: 10, duty_cycle_sta: 10, country: "Japan", tx_power_max: 16, duty_cycle_omit_ctrl_resp: true, pkt_spacing_ms: 2, airtime_min_ms: 2, airtime_max_ms: 100, map_5g_chan: 58 },
		},
		valid_channels: [ 2, 4, 6, 8, 13, 15, 17, 19, 21, 36, 38 ],
		default_channel: 36
	},
	"US": {
		country_name: "USA",
		channels: {
			"3": { country_code: "US", bw: 1, s1g_chan: 3, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 903.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "USA", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 136 },
			"5": { country_code: "US", bw: 1, s1g_chan: 5, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 904.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "USA", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 36 },
			"7": { country_code: "US", bw: 1, s1g_chan: 7, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 905.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "USA", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 40 },
			"9": { country_code: "US", bw: 1, s1g_chan: 9, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 906.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "USA", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 44 },
			"11": { country_code: "US", bw: 1, s1g_chan: 11, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 907.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "USA", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 48 },
			"13": { country_code: "US", bw: 1, s1g_chan: 13, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 908.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "USA", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 52 },
			"15": { country_code: "US", bw: 1, s1g_chan: 15, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 909.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "USA", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 56 },
			"17": { country_code: "US", bw: 1, s1g_chan: 17, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 910.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "USA", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 60 },
			"19": { country_code: "US", bw: 1, s1g_chan: 19, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 911.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "USA", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 64 },
			"21": { country_code: "US", bw: 1, s1g_chan: 21, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 912.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "USA", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 100 },
			"23": { country_code: "US", bw: 1, s1g_chan: 23, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 913.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "USA", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 104 },
			"25": { country_code: "US", bw: 1, s1g_chan: 25, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 914.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "USA", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 108 },
			"27": { country_code: "US", bw: 1, s1g_chan: 27, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 915.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "USA", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 112 },
			"29": { country_code: "US", bw: 1, s1g_chan: 29, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 916.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "USA", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 116 },
			"31": { country_code: "US", bw: 1, s1g_chan: 31, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 917.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "USA", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 120 },
			"33": { country_code: "US", bw: 1, s1g_chan: 33, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 918.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "USA", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 124 },
			"35": { country_code: "US", bw: 1, s1g_chan: 35, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 919.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "USA", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 128 },
			"37": { country_code: "US", bw: 1, s1g_chan: 37, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 920.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "USA", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 149 },
			"39": { country_code: "US", bw: 1, s1g_chan: 39, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 921.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "USA", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 153 },
			"41": { country_code: "US", bw: 1, s1g_chan: 41, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 922.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "USA", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 157 },
			"43": { country_code: "US", bw: 1, s1g_chan: 43, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 923.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "USA", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 161 },
			"45": { country_code: "US", bw: 1, s1g_chan: 45, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 924.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "USA", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 165 },
			"47": { country_code: "US", bw: 1, s1g_chan: 47, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 925.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "USA", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 169 },
			"49": { country_code: "US", bw: 1, s1g_chan: 49, s1g_op_class: 1, global_op_class: 68, centre_freq_mhz: 926.5, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "USA", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 173 },
			"6": { country_code: "US", bw: 2, s1g_chan: 6, s1g_op_class: 2, global_op_class: 69, centre_freq_mhz: 905, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "USA", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 38 },
			"10": { country_code: "US", bw: 2, s1g_chan: 10, s1g_op_class: 2, global_op_class: 69, centre_freq_mhz: 907, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "USA", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 46 },
			"14": { country_code: "US", bw: 2, s1g_chan: 14, s1g_op_class: 2, global_op_class: 69, centre_freq_mhz: 909, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "USA", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 54 },
			"18": { country_code: "US", bw: 2, s1g_chan: 18, s1g_op_class: 2, global_op_class: 69, centre_freq_mhz: 911, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "USA", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 62 },
			"22": { country_code: "US", bw: 2, s1g_chan: 22, s1g_op_class: 2, global_op_class: 69, centre_freq_mhz: 913, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "USA", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 102 },
			"26": { country_code: "US", bw: 2, s1g_chan: 26, s1g_op_class: 2, global_op_class: 69, centre_freq_mhz: 915, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "USA", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 110 },
			"30": { country_code: "US", bw: 2, s1g_chan: 30, s1g_op_class: 2, global_op_class: 69, centre_freq_mhz: 917, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "USA", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 118 },
			"34": { country_code: "US", bw: 2, s1g_chan: 34, s1g_op_class: 2, global_op_class: 69, centre_freq_mhz: 919, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "USA", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 126 },
			"38": { country_code: "US", bw: 2, s1g_chan: 38, s1g_op_class: 2, global_op_class: 69, centre_freq_mhz: 921, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "USA", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 151 },
			"42": { country_code: "US", bw: 2, s1g_chan: 42, s1g_op_class: 2, global_op_class: 69, centre_freq_mhz: 923, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "USA", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 159 },
			"46": { country_code: "US", bw: 2, s1g_chan: 46, s1g_op_class: 2, global_op_class: 69, centre_freq_mhz: 925, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "USA", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 167 },
			"8": { country_code: "US", bw: 4, s1g_chan: 8, s1g_op_class: 3, global_op_class: 70, centre_freq_mhz: 906, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "USA", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 42 },
			"16": { country_code: "US", bw: 4, s1g_chan: 16, s1g_op_class: 3, global_op_class: 70, centre_freq_mhz: 910, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "USA", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 58 },
			"24": { country_code: "US", bw: 4, s1g_chan: 24, s1g_op_class: 3, global_op_class: 70, centre_freq_mhz: 914, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "USA", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 106 },
			"32": { country_code: "US", bw: 4, s1g_chan: 32, s1g_op_class: 3, global_op_class: 70, centre_freq_mhz: 918, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "USA", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 122 },
			"40": { country_code: "US", bw: 4, s1g_chan: 40, s1g_op_class: 3, global_op_class: 70, centre_freq_mhz: 922, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "USA", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 155 },
			"12": { country_code: "US", bw: 8, s1g_chan: 12, s1g_op_class: 4, global_op_class: 71, centre_freq_mhz: 908, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "USA", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 50 },
			"28": { country_code: "US", bw: 8, s1g_chan: 28, s1g_op_class: 4, global_op_class: 71, centre_freq_mhz: 916, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "USA", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 114 },
			"44": { country_code: "US", bw: 8, s1g_chan: 44, s1g_op_class: 4, global_op_class: 71, centre_freq_mhz: 924, duty_cycle_ap: 100, duty_cycle_sta: 100, country: "USA", tx_power_max: 36, duty_cycle_omit_ctrl_resp: false, pkt_spacing_ms: 0, airtime_min_ms: 0, airtime_max_ms: 0, map_5g_chan: 163 },
		},
		valid_channels: [ 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 49 ],
		default_channel: 12
	}
};

// ---------------------------------------------------------------------------
// Lookup API
// ---------------------------------------------------------------------------

// Is 'country' a HaLow regulatory domain present in the channel map?
// Returns true/false; a null country is never valid.
function halow_has_country(country) {
	return (country != null) && (country in CHANNEL_MAP);
}

// All S1G channel numbers usable in 'country', across every bandwidth.
// Returns an empty array for an unknown country, so the result is always safe
// to iterate.
function halow_valid_channels(country) {
	let entry = CHANNEL_MAP[country];
	return entry ? entry.valid_channels : [];
}

// Preferred S1G channel for 'country' when none was requested.
// Returns null for an unknown country, so callers must handle null.
function halow_default_channel(country) {
	let entry = CHANNEL_MAP[country];
	return entry ? entry.default_channel : null;
}

// Global operating class for the given country/channel pair.
// Returns null when the country or the channel is not in the map.
function halow_lookup_op_class(country, chan) {
	let entry = CHANNEL_MAP[country];
	if (!entry)
		return null;
	let row = entry.channels[sprintf("%d", chan)];
	return row ? row.global_op_class : null;
}

// Centre frequency in MHz for the given country/channel pair (may be
// fractional, e.g. 916.5). Returns null when the country or channel is
// not in the map.
function halow_centre_freq(country, chan) {
	let entry = CHANNEL_MAP[country];
	if (!entry)
		return null;
	let row = entry.channels[sprintf("%d", chan)];
	return row ? row.centre_freq_mhz : null;
}

// Map 'country' onto a regulatory domain the HaLow chip supports.
// Falls back to 'default_country' and then to 'US', warning on each fallback,
// so the return value is always a country present in the map (never null).
function halow_resolve_country(country, default_country) {
	if (halow_has_country(country))
		return country;
	// First fallback: the supplied default country (e.g. from env / board.json).
	if (halow_has_country(default_country)) {
		warn(sprintf("HaLow: unknown country '%s', falling back to '%s'\n", country, default_country));
		return default_country;
	}
	// Last-resort fallback: 'US' is always present in the table.
	warn(sprintf("HaLow: unknown country '%s' and invalid default '%s', falling back to 'US'\n", country, default_country));
	return 'US';
}

// Validate 'chan' against 'country' and return a usable channel: 'chan' itself
// when it is listed for that country, otherwise the country default (with a
// warning). Returns null for an unknown country, so callers must handle null.
function halow_resolve_channel(country, chan) {
	let entry = CHANNEL_MAP[country];
	if (!entry)
		return null;
	if (entry.channels[sprintf("%d", chan)] != null)
		return chan;
	let fallback = entry.default_channel;
	warn(sprintf("HaLow: invalid channel %s for country '%s', falling back to %d\n", chan, country, fallback));
	return fallback;
}

return {
	CHANNEL_MAP,
	halow_has_country,
	halow_valid_channels,
	halow_default_channel,
	halow_lookup_op_class,
	halow_centre_freq,
	halow_resolve_country,
	halow_resolve_channel
};

