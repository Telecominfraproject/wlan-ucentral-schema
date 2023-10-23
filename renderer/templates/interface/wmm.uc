{%

let wmm = state?.globals?.wireless_multimedia;

if (!length(wmm))
	return;

let class = {
	"CS0": 0,
	"CS1": 8,
	"CS2": 16,
	"CS3": 24,
	"CS4": 32,
	"CS5": 40,
	"CS6": 48,
	"CS7": 56,
	"AF11": 10,
	"AF12": 12,
	"AF13": 14,
	"AF21": 18,
	"AF22": 20,
	"AF23": 22,
	"AF31": 26,
	"AF32": 28,
	"AF33": 30,
	"AF41": 34,
	"AF42": 36,
	"AF43": 38,
	"EF": 46,
	"VA": 44,
	"LE": 1,
	"DF": 0,

	/* fake entry used by rfc8325 */
	"MIN": 2
};

let profiles = {
	"rfc8325": {
		"defaults": {
			"UP0": [ "MIN", "CS2" ],
			"UP1": [ "CS1" ],
			"UP3": [ "AF21", "AF23" ],
			"UP4": [ "CS3", "AF43" ],
			"UP5": [ "CS5" ],
			"UP6": [ "VA", "EF" ],
			"UP7": [ "CS6", "CS7" ]
		}
	},
	"3gpp": {
		"defaults": {
			"UP0": [ "DF" ],
			"UP1": [ "CS1" ],
			"UP2": [ "AF11", "AF13" ],
			"UP3": [ "AF21", "AF23" ],
			"UP4": [ "CS3", "AF33" ],
			"UP5": [ "CS5", "AF43" ],
			"UP6": [ "CS4" ],
			"UP7": [ "CS6" ]
		},
		"exceptions": {
			"UP6": [ "EF" ]
		}
	},
	"enterprise": {
		"defaults": {
			"UP0": [ "DF" ],
			"UP1": [ "CS1" ],
			"UP2": [ "AF11", "AF13" ],
			"UP3": [ "CS2", "AF23" ],
			"UP4": [ "CS3", "AF33" ],
			"UP5": [ "CS5" ],
			"UP6": [ "CS4" ],
			"UP7": [ "CS6" ]
		},
		"exceptions": {
			"UP5": [ "AF41", "AF42", "AF43" ],
			"UP6": [ "EF" ],
			"UP7": [ "CS6" ]
		}
	}
};

function qos_map() {
	let up_map = [];

	if (wmm.profile)
		wmm = profiles[wmm.profile];

	if (!length(wmm.defaults))
		wmm.defaults = { };

	if (!length(wmm.exceptions))
		wmm.exceptions = { };

	for (let prio = 0; prio < 8; prio++) {
		let up = wmm.exceptions["UP" + prio] || [];
		let len = length(up);

		if (!length(up))
			continue;

		for (let idx = 0; idx < len; idx++) {
			push(up_map, class[up[idx]]);
			push(up_map, prio);
		}
	}

	for (let prio = 0; prio < 8; prio++) {
		let up = wmm.defaults["UP" + prio];

		if (length(up)) {
			push(up_map, class[up[0]]);
			push(up_map, class[up[1] || up[0]]);
		} else {
			push(up_map, 255);
			push(up_map, 255);
		}
	}
	let qos_map = join(",", up_map);

	return qos_map;
}
%}
set wireless.{{ section }}.iw_qos_map_set={{ s(qos_map()) }}
