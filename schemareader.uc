// Automatically generated from ./ucentral.schema.pretty.json - do not edit!
"use strict";

function matchUcCidr4(value) {
	let m = match(value, /^(auto|[0-9.]+)\/([0-9]+)$/);
	return m ? ((m[1] == "auto" || length(iptoarr(m[1])) == 4) && +m[2] <= 32) : false;
}

function matchUcCidr6(value) {
	let m = match(value, /^(auto|[0-9a-fA-F:.]+)\/([0-9]+)$/);
	return m ? ((m[1] == "auto" || length(iptoarr(m[1])) == 16) && +m[2] <= 128) : false;
}

function matchUcCidr(value) {
	let m = match(value, /^(auto|[0-9a-fA-F:.]+)\/([0-9]+)$/);
	if (!m) return false;
	let l = (m[1] == "auto") ? 16 : length(iptoarr(m[1]));
	return (l > 0 && +m[2] <= (l * 8));
}

function matchUcMac(value) {
	return match(value, /^[0-9a-f][0-9a-f]:[0-9a-f][0-9a-f]:[0-9a-f][0-9a-f]:[0-9a-f][0-9a-f]:[0-9a-f][0-9a-f]:[0-9a-f][0-9a-f]$/i);
}

function matchUcMobility(value) {
	return match(value, /^[0-9a-f][0-9a-f][0-9a-f][0-9a-f]$/i);
}

function matchUcHost(value) {
	if (length(iptoarr(value)) != 0) return true;
	if (length(value) > 255) return false;
	let labels = split(value, ".");
	return (length(filter(labels, label => !match(label, /^([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9])$/))) == 0 && length(labels) > 0);
}

function matchUcTimeout(value) {
	return match(value, /^[0-9]+[smhdw]$/);
}

function matchUcBase64(value) {
	return b64dec(value) != null;
}

function matchUcPortrange(value) {
	let ports = match(value, /^([0-9]|[1-9][0-9]*)(-([0-9]|[1-9][0-9]*))?$/);
	if (!ports) return false;
	let min = +ports[1], max = ports[2] ? +ports[3] : min;
	return (min <= 65535 && max <= 65535 && max >= min);
}

function matchHostname(value) {
	if (length(value) > 255) return false;
	let labels = split(value, ".");
	return (length(filter(labels, label => !match(label, /^([a-zA-Z0-9]{1,2}|[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9])$/))) == 0 && length(labels) > 0);
}

function matchUcFqdn(value) {
	if (length(value) > 255) return false;
	let labels = split(value, ".");
	return (length(filter(labels, label => !match(label, /^([a-zA-Z0-9]{1,2}|[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9])$/))) == 0 && length(labels) > 1);
}

function matchUcIp(value) {
	return (length(iptoarr(value)) == 4 || length(iptoarr(value)) == 16);
}

function matchIpv4(value) {
	return (length(iptoarr(value)) == 4);
}

function matchIpv6(value) {
	return (length(iptoarr(value)) == 16);
}

function matchUri(value) {
	if (index(value, "data:") == 0) return true;
	let m = match(value, /^[a-z+-]+:\/\/([^\/]+).*$/);
	if (!m) return false;
	if (length(iptoarr(m[1])) != 0) return true;
	if (length(m[1]) > 255) return false;
	let labels = split(m[1], ".");
	return (length(filter(labels, label => !match(label, /^([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9])$/))) == 0 && length(labels) > 0);
}

function instantiateUnit(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseName(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "name")) {
			obj.name = parseName(location + "/name", value["name"], errors);
		}

		function parseHostname(location, value, errors) {
			if (type(value) == "string") {
				if (!matchHostname(value))
					push(errors, [ location, "must be a valid hostname" ]);

			}

			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "hostname")) {
			obj.hostname = parseHostname(location + "/hostname", value["hostname"], errors);
		}

		function parseLocation(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "location")) {
			obj.location = parseLocation(location + "/location", value["location"], errors);
		}

		function parseTimezone(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "timezone")) {
			obj.timezone = parseTimezone(location + "/timezone", value["timezone"], errors);
		}

		function parseLedsActive(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "leds-active")) {
			obj.leds_active = parseLedsActive(location + "/leds-active", value["leds-active"], errors);
		}
		else {
			obj.leds_active = true;
		}

		function parseRandomPassword(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "random-password")) {
			obj.random_password = parseRandomPassword(location + "/random-password", value["random-password"], errors);
		}
		else {
			obj.random_password = false;
		}

		function parseBeaconAdvertisement(location, value, errors) {
			if (type(value) == "object") {
				let obj = {};

				function parseDeviceName(location, value, errors) {
					if (type(value) != "bool")
						push(errors, [ location, "must be of type boolean" ]);

					return value;
				}

				if (exists(value, "device-name")) {
					obj.device_name = parseDeviceName(location + "/device-name", value["device-name"], errors);
				}

				function parseDeviceSerial(location, value, errors) {
					if (type(value) != "bool")
						push(errors, [ location, "must be of type boolean" ]);

					return value;
				}

				if (exists(value, "device-serial")) {
					obj.device_serial = parseDeviceSerial(location + "/device-serial", value["device-serial"], errors);
				}

				function parseNetworkId(location, value, errors) {
					if (type(value) != "int")
						push(errors, [ location, "must be of type integer" ]);

					return value;
				}

				if (exists(value, "network-id")) {
					obj.network_id = parseNetworkId(location + "/network-id", value["network-id"], errors);
				}

				return obj;
			}

			if (type(value) != "object")
				push(errors, [ location, "must be of type object" ]);

			return value;
		}

		if (exists(value, "beacon-advertisement")) {
			obj.beacon_advertisement = parseBeaconAdvertisement(location + "/beacon-advertisement", value["beacon-advertisement"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateGlobalsWirelessMultimediaClassSelector(location, value, errors) {
	if (type(value) == "array") {
		function parseItem(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			if (!(value in [ "CS0", "CS1", "CS2", "CS3", "CS4", "CS5", "CS6", "CS7", "AF11", "AF12", "AF13", "AF21", "AF22", "AF23", "AF31", "AF32", "AF33", "AF41", "AF42", "AF43", "DF", "EF", "VA", "LE" ]))
				push(errors, [ location, "must be one of \"CS0\", \"CS1\", \"CS2\", \"CS3\", \"CS4\", \"CS5\", \"CS6\", \"CS7\", \"AF11\", \"AF12\", \"AF13\", \"AF21\", \"AF22\", \"AF23\", \"AF31\", \"AF32\", \"AF33\", \"AF41\", \"AF42\", \"AF43\", \"DF\", \"EF\", \"VA\" or \"LE\"" ]);

			return value;
		}

		return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
	}

	if (type(value) != "array")
		push(errors, [ location, "must be of type array" ]);

	return value;
}

function instantiateGlobalsWirelessMultimediaTable(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		if (exists(value, "UP0")) {
			obj.UP0 = instantiateGlobalsWirelessMultimediaClassSelector(location + "/UP0", value["UP0"], errors);
		}

		if (exists(value, "UP1")) {
			obj.UP1 = instantiateGlobalsWirelessMultimediaClassSelector(location + "/UP1", value["UP1"], errors);
		}

		if (exists(value, "UP2")) {
			obj.UP2 = instantiateGlobalsWirelessMultimediaClassSelector(location + "/UP2", value["UP2"], errors);
		}

		if (exists(value, "UP3")) {
			obj.UP3 = instantiateGlobalsWirelessMultimediaClassSelector(location + "/UP3", value["UP3"], errors);
		}

		if (exists(value, "UP4")) {
			obj.UP4 = instantiateGlobalsWirelessMultimediaClassSelector(location + "/UP4", value["UP4"], errors);
		}

		if (exists(value, "UP5")) {
			obj.UP5 = instantiateGlobalsWirelessMultimediaClassSelector(location + "/UP5", value["UP5"], errors);
		}

		if (exists(value, "UP6")) {
			obj.UP6 = instantiateGlobalsWirelessMultimediaClassSelector(location + "/UP6", value["UP6"], errors);
		}

		if (exists(value, "UP7")) {
			obj.UP7 = instantiateGlobalsWirelessMultimediaClassSelector(location + "/UP7", value["UP7"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateGlobalsWirelessMultimediaProfile(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseProfile(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			if (!(value in [ "enterprise", "rfc8325", "3gpp" ]))
				push(errors, [ location, "must be one of \"enterprise\", \"rfc8325\" or \"3gpp\"" ]);

			return value;
		}

		if (exists(value, "profile")) {
			obj.profile = parseProfile(location + "/profile", value["profile"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateGlobals(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseIpv4Network(location, value, errors) {
			if (type(value) == "string") {
				if (!matchUcCidr4(value))
					push(errors, [ location, "must be a valid IPv4 CIDR" ]);

			}

			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "ipv4-network")) {
			obj.ipv4_network = parseIpv4Network(location + "/ipv4-network", value["ipv4-network"], errors);
		}

		function parseIpv6Network(location, value, errors) {
			if (type(value) == "string") {
				if (!matchUcCidr6(value))
					push(errors, [ location, "must be a valid IPv6 CIDR" ]);

			}

			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "ipv6-network")) {
			obj.ipv6_network = parseIpv6Network(location + "/ipv6-network", value["ipv6-network"], errors);
		}

		function parseWirelessMultimedia(location, value, errors) {
			function parseVariant0(location, value, errors) {
				value = instantiateGlobalsWirelessMultimediaTable(location, value, errors);

				return value;
			}

			function parseVariant1(location, value, errors) {
				value = instantiateGlobalsWirelessMultimediaProfile(location, value, errors);

				return value;
			}

			let success = 0, tryval, tryerr, vvalue = null, verrors = [];

			tryerr = [];
			tryval = parseVariant0(location, value, tryerr);
			if (!length(tryerr)) {
				if (type(vvalue) == "object" && type(tryval) == "object")
					vvalue = { ...vvalue, ...tryval };
				else
					vvalue = tryval;

				success++;
			}
			else {
				push(verrors, join(" and\n", map(tryerr, err => "\t - " + err[1])));
			}

			tryerr = [];
			tryval = parseVariant1(location, value, tryerr);
			if (!length(tryerr)) {
				if (type(vvalue) == "object" && type(tryval) == "object")
					vvalue = { ...vvalue, ...tryval };
				else
					vvalue = tryval;

				success++;
			}
			else {
				push(verrors, join(" and\n", map(tryerr, err => "\t - " + err[1])));
			}

			if (success == 0) {
				if (length(verrors))
					push(errors, [ location, "must match at least one of the following constraints:\n" + join("\n- or -\n", verrors) ]);
				else
					push(errors, [ location, "must match only one variant" ]);
				return null;
			}

			value = vvalue;

			return value;
		}

		if (exists(value, "wireless-multimedia")) {
			obj.wireless_multimedia = parseWirelessMultimedia(location + "/wireless-multimedia", value["wireless-multimedia"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateInterfaceSsidEncryption(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseProto(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			if (!(value in [ "none", "owe", "owe-transition", "psk", "psk2", "psk-mixed", "psk2-radius", "wpa", "wpa2", "wpa-mixed", "sae", "sae-mixed", "wpa3", "wpa3-192", "wpa3-mixed" ]))
				push(errors, [ location, "must be one of \"none\", \"owe\", \"owe-transition\", \"psk\", \"psk2\", \"psk-mixed\", \"psk2-radius\", \"wpa\", \"wpa2\", \"wpa-mixed\", \"sae\", \"sae-mixed\", \"wpa3\", \"wpa3-192\" or \"wpa3-mixed\"" ]);

			return value;
		}

		if (exists(value, "proto")) {
			obj.proto = parseProto(location + "/proto", value["proto"], errors);
		}

		function parseKey(location, value, errors) {
			if (type(value) == "string") {
				if (length(value) > 63)
					push(errors, [ location, "must be at most 63 characters long" ]);

				if (length(value) < 8)
					push(errors, [ location, "must be at least 8 characters long" ]);

			}

			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "key")) {
			obj.key = parseKey(location + "/key", value["key"], errors);
		}

		function parseIeee80211w(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			if (!(value in [ "disabled", "optional", "required" ]))
				push(errors, [ location, "must be one of \"disabled\", \"optional\" or \"required\"" ]);

			return value;
		}

		if (exists(value, "ieee80211w")) {
			obj.ieee80211w = parseIeee80211w(location + "/ieee80211w", value["ieee80211w"], errors);
		}
		else {
			obj.ieee80211w = "disabled";
		}

		function parseKeyCaching(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "key-caching")) {
			obj.key_caching = parseKeyCaching(location + "/key-caching", value["key-caching"], errors);
		}
		else {
			obj.key_caching = true;
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateDefinitions(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseWirelessEncryption(location, value, errors) {
			if (type(value) != "object")
				push(errors, [ location, "must be of type object" ]);

			return value;
		}

		if (exists(value, "wireless-encryption")) {
			obj.wireless_encryption = parseWirelessEncryption(location + "/wireless-encryption", value["wireless-encryption"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateEthernet(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseSelectPorts(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "select-ports")) {
			obj.select_ports = parseSelectPorts(location + "/select-ports", value["select-ports"], errors);
		}

		function parseSpeed(location, value, errors) {
			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			if (!(value in [ 10, 100, 1000, 2500, 5000, 10000 ]))
				push(errors, [ location, "must be one of 10, 100, 1000, 2500, 5000 or 10000" ]);

			return value;
		}

		if (exists(value, "speed")) {
			obj.speed = parseSpeed(location + "/speed", value["speed"], errors);
		}

		function parseEnabled(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "enabled")) {
			obj.enabled = parseEnabled(location + "/enabled", value["enabled"], errors);
		}
		else {
			obj.enabled = true;
		}

		function parseServices(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "services")) {
			obj.services = parseServices(location + "/services", value["services"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateSwitch(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parsePortMirror(location, value, errors) {
			if (type(value) == "object") {
				let obj = {};

				function parseMonitorPorts(location, value, errors) {
					if (type(value) == "array") {
						function parseItem(location, value, errors) {
							if (type(value) != "string")
								push(errors, [ location, "must be of type string" ]);

							return value;
						}

						return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
					}

					if (type(value) != "array")
						push(errors, [ location, "must be of type array" ]);

					return value;
				}

				if (exists(value, "monitor-ports")) {
					obj.monitor_ports = parseMonitorPorts(location + "/monitor-ports", value["monitor-ports"], errors);
				}

				function parseAnalysisPort(location, value, errors) {
					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					return value;
				}

				if (exists(value, "analysis-port")) {
					obj.analysis_port = parseAnalysisPort(location + "/analysis-port", value["analysis-port"], errors);
				}

				return obj;
			}

			if (type(value) != "object")
				push(errors, [ location, "must be of type object" ]);

			return value;
		}

		if (exists(value, "port-mirror")) {
			obj.port_mirror = parsePortMirror(location + "/port-mirror", value["port-mirror"], errors);
		}

		function parseLoopDetection(location, value, errors) {
			if (type(value) == "object") {
				let obj = {};

				function parseProtocol(location, value, errors) {
					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					if (!(value in [ "rstp" ]))
						push(errors, [ location, "must be one of \"rstp\"" ]);

					return value;
				}

				if (exists(value, "protocol")) {
					obj.protocol = parseProtocol(location + "/protocol", value["protocol"], errors);
				}
				else {
					obj.protocol = "rstp";
				}

				function parseRoles(location, value, errors) {
					if (type(value) == "array") {
						function parseItem(location, value, errors) {
							if (type(value) != "string")
								push(errors, [ location, "must be of type string" ]);

							if (!(value in [ "upstream", "downstream" ]))
								push(errors, [ location, "must be one of \"upstream\" or \"downstream\"" ]);

							return value;
						}

						return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
					}

					if (type(value) != "array")
						push(errors, [ location, "must be of type array" ]);

					return value;
				}

				if (exists(value, "roles")) {
					obj.roles = parseRoles(location + "/roles", value["roles"], errors);
				}

				return obj;
			}

			if (type(value) != "object")
				push(errors, [ location, "must be of type object" ]);

			return value;
		}

		if (exists(value, "loop-detection")) {
			obj.loop_detection = parseLoopDetection(location + "/loop-detection", value["loop-detection"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateRadioRates(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseBeacon(location, value, errors) {
			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			if (!(value in [ 0, 1000, 2000, 5500, 6000, 9000, 11000, 12000, 18000, 24000, 36000, 48000, 54000 ]))
				push(errors, [ location, "must be one of 0, 1000, 2000, 5500, 6000, 9000, 11000, 12000, 18000, 24000, 36000, 48000 or 54000" ]);

			return value;
		}

		if (exists(value, "beacon")) {
			obj.beacon = parseBeacon(location + "/beacon", value["beacon"], errors);
		}
		else {
			obj.beacon = 6000;
		}

		function parseMulticast(location, value, errors) {
			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			if (!(value in [ 0, 1000, 2000, 5500, 6000, 9000, 11000, 12000, 18000, 24000, 36000, 48000, 54000 ]))
				push(errors, [ location, "must be one of 0, 1000, 2000, 5500, 6000, 9000, 11000, 12000, 18000, 24000, 36000, 48000 or 54000" ]);

			return value;
		}

		if (exists(value, "multicast")) {
			obj.multicast = parseMulticast(location + "/multicast", value["multicast"], errors);
		}
		else {
			obj.multicast = 24000;
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateRadioHe(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseMultipleBssid(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "multiple-bssid")) {
			obj.multiple_bssid = parseMultipleBssid(location + "/multiple-bssid", value["multiple-bssid"], errors);
		}
		else {
			obj.multiple_bssid = false;
		}

		function parseEma(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "ema")) {
			obj.ema = parseEma(location + "/ema", value["ema"], errors);
		}
		else {
			obj.ema = false;
		}

		function parseBssColor(location, value, errors) {
			if (type(value) in [ "int", "double" ]) {
				if (value > 64)
					push(errors, [ location, "must be lower than or equal to 64" ]);

				if (value < 0)
					push(errors, [ location, "must be bigger than or equal to 0" ]);

			}

			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "bss-color")) {
			obj.bss_color = parseBssColor(location + "/bss-color", value["bss-color"], errors);
		}
		else {
			obj.bss_color = 0;
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateRadioHe6ghz(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parsePowerType(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			if (!(value in [ "indoor-power-indoor", "standard-power", "very-low-power" ]))
				push(errors, [ location, "must be one of \"indoor-power-indoor\", \"standard-power\" or \"very-low-power\"" ]);

			return value;
		}

		if (exists(value, "power-type")) {
			obj.power_type = parsePowerType(location + "/power-type", value["power-type"], errors);
		}
		else {
			obj.power_type = "very-low-power";
		}

		function parseController(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "controller")) {
			obj.controller = parseController(location + "/controller", value["controller"], errors);
		}

		function parseCaCertificate(location, value, errors) {
			if (type(value) == "string") {
				if (!matchUcBase64(value))
					push(errors, [ location, "must be a valid base64 encoded data" ]);

			}

			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "ca-certificate")) {
			obj.ca_certificate = parseCaCertificate(location + "/ca-certificate", value["ca-certificate"], errors);
		}

		function parseSerialNumber(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "serial-number")) {
			obj.serial_number = parseSerialNumber(location + "/serial-number", value["serial-number"], errors);
		}

		function parseRequestId(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "request-id")) {
			obj.request_id = parseRequestId(location + "/request-id", value["request-id"], errors);
		}

		function parseCertificateIds(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "certificate-ids")) {
			obj.certificate_ids = parseCertificateIds(location + "/certificate-ids", value["certificate-ids"], errors);
		}

		function parseMinimumPower(location, value, errors) {
			if (!(type(value) in [ "int", "double" ]))
				push(errors, [ location, "must be of type number" ]);

			return value;
		}

		if (exists(value, "minimum-power")) {
			obj.minimum_power = parseMinimumPower(location + "/minimum-power", value["minimum-power"], errors);
		}

		function parseFrequencyRanges(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "frequency-ranges")) {
			obj.frequency_ranges = parseFrequencyRanges(location + "/frequency-ranges", value["frequency-ranges"], errors);
		}

		function parseOperatingClasses(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					if (!(type(value) in [ "int", "double" ]))
						push(errors, [ location, "must be of type number" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "operating-classes")) {
			obj.operating_classes = parseOperatingClasses(location + "/operating-classes", value["operating-classes"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateRadio(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseBand(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			if (!(value in [ "2G", "5G", "5G-lower", "5G-upper", "6G" ]))
				push(errors, [ location, "must be one of \"2G\", \"5G\", \"5G-lower\", \"5G-upper\" or \"6G\"" ]);

			return value;
		}

		if (exists(value, "band")) {
			obj.band = parseBand(location + "/band", value["band"], errors);
		}

		function parseBandwidth(location, value, errors) {
			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			if (!(value in [ 5, 10, 20 ]))
				push(errors, [ location, "must be one of 5, 10 or 20" ]);

			return value;
		}

		if (exists(value, "bandwidth")) {
			obj.bandwidth = parseBandwidth(location + "/bandwidth", value["bandwidth"], errors);
		}

		function parseChannel(location, value, errors) {
			function parseVariant0(location, value, errors) {
				if (type(value) in [ "int", "double" ]) {
					if (value > 196)
						push(errors, [ location, "must be lower than or equal to 196" ]);

					if (value < 1)
						push(errors, [ location, "must be bigger than or equal to 1" ]);

				}

				if (type(value) != "int")
					push(errors, [ location, "must be of type integer" ]);

				return value;
			}

			function parseVariant1(location, value, errors) {
				if (type(value) != "string")
					push(errors, [ location, "must be of type string" ]);

				if (value != "auto")
					push(errors, [ location, "must have value \"auto\"" ]);

				return value;
			}

			let success = 0, tryval, tryerr, vvalue = null, verrors = [];

			tryerr = [];
			tryval = parseVariant0(location, value, tryerr);
			if (!length(tryerr)) {
				if (type(vvalue) == "object" && type(tryval) == "object")
					vvalue = { ...vvalue, ...tryval };
				else
					vvalue = tryval;

				success++;
			}
			else {
				push(verrors, join(" and\n", map(tryerr, err => "\t - " + err[1])));
			}

			tryerr = [];
			tryval = parseVariant1(location, value, tryerr);
			if (!length(tryerr)) {
				if (type(vvalue) == "object" && type(tryval) == "object")
					vvalue = { ...vvalue, ...tryval };
				else
					vvalue = tryval;

				success++;
			}
			else {
				push(verrors, join(" and\n", map(tryerr, err => "\t - " + err[1])));
			}

			if (success != 1) {
				if (length(verrors))
					push(errors, [ location, "must match exactly one of the following constraints:\n" + join("\n- or -\n", verrors) ]);
				else
					push(errors, [ location, "must match only one variant" ]);
				return null;
			}

			value = vvalue;

			return value;
		}

		if (exists(value, "channel")) {
			obj.channel = parseChannel(location + "/channel", value["channel"], errors);
		}

		function parseValidChannels(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					if (type(value) in [ "int", "double" ]) {
						if (value > 196)
							push(errors, [ location, "must be lower than or equal to 196" ]);

						if (value < 1)
							push(errors, [ location, "must be bigger than or equal to 1" ]);

					}

					if (type(value) != "int")
						push(errors, [ location, "must be of type integer" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "valid-channels")) {
			obj.valid_channels = parseValidChannels(location + "/valid-channels", value["valid-channels"], errors);
		}

		function parseAcsExclude6ghzNonPsc(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "acs-exclude-6ghz-non-psc")) {
			obj.acs_exclude_6ghz_non_psc = parseAcsExclude6ghzNonPsc(location + "/acs-exclude-6ghz-non-psc", value["acs-exclude-6ghz-non-psc"], errors);
		}
		else {
			obj.acs_exclude_6ghz_non_psc = false;
		}

		function parseCountry(location, value, errors) {
			if (type(value) == "string") {
				if (length(value) > 2)
					push(errors, [ location, "must be at most 2 characters long" ]);

				if (length(value) < 2)
					push(errors, [ location, "must be at least 2 characters long" ]);

			}

			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "country")) {
			obj.country = parseCountry(location + "/country", value["country"], errors);
		}

		function parseAllowDfs(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "allow-dfs")) {
			obj.allow_dfs = parseAllowDfs(location + "/allow-dfs", value["allow-dfs"], errors);
		}
		else {
			obj.allow_dfs = true;
		}

		function parseChannelMode(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			if (!(value in [ "HT", "VHT", "HE", "EHT" ]))
				push(errors, [ location, "must be one of \"HT\", \"VHT\", \"HE\" or \"EHT\"" ]);

			return value;
		}

		if (exists(value, "channel-mode")) {
			obj.channel_mode = parseChannelMode(location + "/channel-mode", value["channel-mode"], errors);
		}
		else {
			obj.channel_mode = "HE";
		}

		function parseChannelWidth(location, value, errors) {
			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			if (!(value in [ 20, 40, 80, 160, 320, 8080 ]))
				push(errors, [ location, "must be one of 20, 40, 80, 160, 320 or 8080" ]);

			return value;
		}

		if (exists(value, "channel-width")) {
			obj.channel_width = parseChannelWidth(location + "/channel-width", value["channel-width"], errors);
		}
		else {
			obj.channel_width = 80;
		}

		function parseRequireMode(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			if (!(value in [ "HT", "VHT", "HE" ]))
				push(errors, [ location, "must be one of \"HT\", \"VHT\" or \"HE\"" ]);

			return value;
		}

		if (exists(value, "require-mode")) {
			obj.require_mode = parseRequireMode(location + "/require-mode", value["require-mode"], errors);
		}

		function parseMimo(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			if (!(value in [ "1x1", "2x2", "3x3", "4x4", "5x5", "6x6", "7x7", "8x8" ]))
				push(errors, [ location, "must be one of \"1x1\", \"2x2\", \"3x3\", \"4x4\", \"5x5\", \"6x6\", \"7x7\" or \"8x8\"" ]);

			return value;
		}

		if (exists(value, "mimo")) {
			obj.mimo = parseMimo(location + "/mimo", value["mimo"], errors);
		}

		function parseTxPower(location, value, errors) {
			if (type(value) in [ "int", "double" ]) {
				if (value > 30)
					push(errors, [ location, "must be lower than or equal to 30" ]);

				if (value < 0)
					push(errors, [ location, "must be bigger than or equal to 0" ]);

			}

			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "tx-power")) {
			obj.tx_power = parseTxPower(location + "/tx-power", value["tx-power"], errors);
		}

		function parseLegacyRates(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "legacy-rates")) {
			obj.legacy_rates = parseLegacyRates(location + "/legacy-rates", value["legacy-rates"], errors);
		}
		else {
			obj.legacy_rates = false;
		}

		function parseBeaconInterval(location, value, errors) {
			if (type(value) in [ "int", "double" ]) {
				if (value > 65535)
					push(errors, [ location, "must be lower than or equal to 65535" ]);

				if (value < 15)
					push(errors, [ location, "must be bigger than or equal to 15" ]);

			}

			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "beacon-interval")) {
			obj.beacon_interval = parseBeaconInterval(location + "/beacon-interval", value["beacon-interval"], errors);
		}
		else {
			obj.beacon_interval = 100;
		}

		function parseMaximumClients(location, value, errors) {
			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "maximum-clients")) {
			obj.maximum_clients = parseMaximumClients(location + "/maximum-clients", value["maximum-clients"], errors);
		}

		function parseMaximumClientsIgnoreProbe(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "maximum-clients-ignore-probe")) {
			obj.maximum_clients_ignore_probe = parseMaximumClientsIgnoreProbe(location + "/maximum-clients-ignore-probe", value["maximum-clients-ignore-probe"], errors);
		}

		if (exists(value, "rates")) {
			obj.rates = instantiateRadioRates(location + "/rates", value["rates"], errors);
		}

		if (exists(value, "he-settings")) {
			obj.he_settings = instantiateRadioHe(location + "/he-settings", value["he-settings"], errors);
		}

		if (exists(value, "he-6ghz-settings")) {
			obj.he_6ghz_settings = instantiateRadioHe6ghz(location + "/he-6ghz-settings", value["he-6ghz-settings"], errors);
		}

		function parseHostapdIfaceRaw(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "hostapd-iface-raw")) {
			obj.hostapd_iface_raw = parseHostapdIfaceRaw(location + "/hostapd-iface-raw", value["hostapd-iface-raw"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateInterfaceVlan(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseId(location, value, errors) {
			if (type(value) in [ "int", "double" ]) {
				if (value > 4050)
					push(errors, [ location, "must be lower than or equal to 4050" ]);

			}

			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "id")) {
			obj.id = parseId(location + "/id", value["id"], errors);
		}

		function parseProto(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			if (!(value in [ "802.1ad", "802.1q" ]))
				push(errors, [ location, "must be one of \"802.1ad\" or \"802.1q\"" ]);

			return value;
		}

		if (exists(value, "proto")) {
			obj.proto = parseProto(location + "/proto", value["proto"], errors);
		}
		else {
			obj.proto = "802.1q";
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateInterfaceBridge(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseMtu(location, value, errors) {
			if (type(value) in [ "int", "double" ]) {
				if (value > 65535)
					push(errors, [ location, "must be lower than or equal to 65535" ]);

				if (value < 256)
					push(errors, [ location, "must be bigger than or equal to 256" ]);

			}

			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "mtu")) {
			obj.mtu = parseMtu(location + "/mtu", value["mtu"], errors);
		}

		function parseTxQueueLen(location, value, errors) {
			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "tx-queue-len")) {
			obj.tx_queue_len = parseTxQueueLen(location + "/tx-queue-len", value["tx-queue-len"], errors);
		}

		function parseIsolatePorts(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "isolate-ports")) {
			obj.isolate_ports = parseIsolatePorts(location + "/isolate-ports", value["isolate-ports"], errors);
		}
		else {
			obj.isolate_ports = false;
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateInterfaceEthernet(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseSelectPorts(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "select-ports")) {
			obj.select_ports = parseSelectPorts(location + "/select-ports", value["select-ports"], errors);
		}

		function parseMulticast(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "multicast")) {
			obj.multicast = parseMulticast(location + "/multicast", value["multicast"], errors);
		}
		else {
			obj.multicast = true;
		}

		function parseLearning(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "learning")) {
			obj.learning = parseLearning(location + "/learning", value["learning"], errors);
		}
		else {
			obj.learning = true;
		}

		function parseIsolate(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "isolate")) {
			obj.isolate = parseIsolate(location + "/isolate", value["isolate"], errors);
		}
		else {
			obj.isolate = false;
		}

		function parseMacaddr(location, value, errors) {
			if (type(value) == "string") {
				if (!matchUcMac(value))
					push(errors, [ location, "must be a valid MAC address" ]);

			}

			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "macaddr")) {
			obj.macaddr = parseMacaddr(location + "/macaddr", value["macaddr"], errors);
		}

		function parseReversePathFilter(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "reverse-path-filter")) {
			obj.reverse_path_filter = parseReversePathFilter(location + "/reverse-path-filter", value["reverse-path-filter"], errors);
		}
		else {
			obj.reverse_path_filter = false;
		}

		function parseVlanTag(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			if (!(value in [ "tagged", "un-tagged", "auto" ]))
				push(errors, [ location, "must be one of \"tagged\", \"un-tagged\" or \"auto\"" ]);

			return value;
		}

		if (exists(value, "vlan-tag")) {
			obj.vlan_tag = parseVlanTag(location + "/vlan-tag", value["vlan-tag"], errors);
		}
		else {
			obj.vlan_tag = "auto";
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateInterfaceIpv4Dhcp(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseLeaseFirst(location, value, errors) {
			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "lease-first")) {
			obj.lease_first = parseLeaseFirst(location + "/lease-first", value["lease-first"], errors);
		}

		function parseLeaseCount(location, value, errors) {
			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "lease-count")) {
			obj.lease_count = parseLeaseCount(location + "/lease-count", value["lease-count"], errors);
		}

		function parseLeaseTime(location, value, errors) {
			if (type(value) == "string") {
				if (!matchUcTimeout(value))
					push(errors, [ location, "must be a valid timeout value" ]);

			}

			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "lease-time")) {
			obj.lease_time = parseLeaseTime(location + "/lease-time", value["lease-time"], errors);
		}
		else {
			obj.lease_time = "6h";
		}

		function parseUseDns(location, value, errors) {
			function parseVariant0(location, value, errors) {
				if (type(value) == "string") {
					if (!matchIpv4(value))
						push(errors, [ location, "must be a valid IPv4 address" ]);

				}

				if (type(value) != "string")
					push(errors, [ location, "must be of type string" ]);

				return value;
			}

			function parseVariant1(location, value, errors) {
				if (type(value) == "array") {
					function parseItem(location, value, errors) {
						if (type(value) == "string") {
							if (!matchIpv4(value))
								push(errors, [ location, "must be a valid IPv4 address" ]);

						}

						if (type(value) != "string")
							push(errors, [ location, "must be of type string" ]);

						return value;
					}

					return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
				}

				if (type(value) != "array")
					push(errors, [ location, "must be of type array" ]);

				return value;
			}

			let success = 0, tryval, tryerr, vvalue = null, verrors = [];

			tryerr = [];
			tryval = parseVariant0(location, value, tryerr);
			if (!length(tryerr)) {
				if (type(vvalue) == "object" && type(tryval) == "object")
					vvalue = { ...vvalue, ...tryval };
				else
					vvalue = tryval;

				success++;
			}
			else {
				push(verrors, join(" and\n", map(tryerr, err => "\t - " + err[1])));
			}

			tryerr = [];
			tryval = parseVariant1(location, value, tryerr);
			if (!length(tryerr)) {
				if (type(vvalue) == "object" && type(tryval) == "object")
					vvalue = { ...vvalue, ...tryval };
				else
					vvalue = tryval;

				success++;
			}
			else {
				push(verrors, join(" and\n", map(tryerr, err => "\t - " + err[1])));
			}

			if (success == 0) {
				if (length(verrors))
					push(errors, [ location, "must match at least one of the following constraints:\n" + join("\n- or -\n", verrors) ]);
				else
					push(errors, [ location, "must match only one variant" ]);
				return null;
			}

			value = vvalue;

			return value;
		}

		if (exists(value, "use-dns")) {
			obj.use_dns = parseUseDns(location + "/use-dns", value["use-dns"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateInterfaceIpv4DhcpLease(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseMacaddr(location, value, errors) {
			if (type(value) == "string") {
				if (!matchUcMac(value))
					push(errors, [ location, "must be a valid MAC address" ]);

			}

			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "macaddr")) {
			obj.macaddr = parseMacaddr(location + "/macaddr", value["macaddr"], errors);
		}

		function parseStaticLeaseOffset(location, value, errors) {
			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "static-lease-offset")) {
			obj.static_lease_offset = parseStaticLeaseOffset(location + "/static-lease-offset", value["static-lease-offset"], errors);
		}

		function parseLeaseTime(location, value, errors) {
			if (type(value) == "string") {
				if (!matchUcTimeout(value))
					push(errors, [ location, "must be a valid timeout value" ]);

			}

			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "lease-time")) {
			obj.lease_time = parseLeaseTime(location + "/lease-time", value["lease-time"], errors);
		}
		else {
			obj.lease_time = "6h";
		}

		function parsePublishHostname(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "publish-hostname")) {
			obj.publish_hostname = parsePublishHostname(location + "/publish-hostname", value["publish-hostname"], errors);
		}
		else {
			obj.publish_hostname = true;
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateInterfaceIpv4PortForward(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseProtocol(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			if (!(value in [ "tcp", "udp", "any" ]))
				push(errors, [ location, "must be one of \"tcp\", \"udp\" or \"any\"" ]);

			return value;
		}

		if (exists(value, "protocol")) {
			obj.protocol = parseProtocol(location + "/protocol", value["protocol"], errors);
		}
		else {
			obj.protocol = "any";
		}

		function parseExternalPort(location, value, errors) {
			if (type(value) in [ "int", "double" ]) {
				if (value > 65535)
					push(errors, [ location, "must be lower than or equal to 65535" ]);

				if (value < 0)
					push(errors, [ location, "must be bigger than or equal to 0" ]);

			}

			if (type(value) == "string") {
				if (!matchUcPortrange(value))
					push(errors, [ location, "must be a valid network port range" ]);

			}

			if (type(value) != "int" && type(value) != "string")
				push(errors, [ location, "must be of type integer or string" ]);

			return value;
		}

		if (exists(value, "external-port")) {
			obj.external_port = parseExternalPort(location + "/external-port", value["external-port"], errors);
		}
		else {
			push(errors, [ location, "is required" ]);
		}

		function parseInternalAddress(location, value, errors) {
			if (type(value) == "string") {
				if (!matchIpv4(value))
					push(errors, [ location, "must be a valid IPv4 address" ]);

			}

			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "internal-address")) {
			obj.internal_address = parseInternalAddress(location + "/internal-address", value["internal-address"], errors);
		}
		else {
			push(errors, [ location, "is required" ]);
		}

		function parseInternalPort(location, value, errors) {
			if (type(value) in [ "int", "double" ]) {
				if (value > 65535)
					push(errors, [ location, "must be lower than or equal to 65535" ]);

				if (value < 0)
					push(errors, [ location, "must be bigger than or equal to 0" ]);

			}

			if (type(value) == "string") {
				if (!matchUcPortrange(value))
					push(errors, [ location, "must be a valid network port range" ]);

			}

			if (type(value) != "int" && type(value) != "string")
				push(errors, [ location, "must be of type integer or string" ]);

			return value;
		}

		if (exists(value, "internal-port")) {
			obj.internal_port = parseInternalPort(location + "/internal-port", value["internal-port"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateInterfaceIpv4(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseAddressing(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			if (!(value in [ "dynamic", "static", "none" ]))
				push(errors, [ location, "must be one of \"dynamic\", \"static\" or \"none\"" ]);

			return value;
		}

		if (exists(value, "addressing")) {
			obj.addressing = parseAddressing(location + "/addressing", value["addressing"], errors);
		}

		function parseSubnet(location, value, errors) {
			if (type(value) == "string") {
				if (!matchUcCidr4(value))
					push(errors, [ location, "must be a valid IPv4 CIDR" ]);

			}

			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "subnet")) {
			obj.subnet = parseSubnet(location + "/subnet", value["subnet"], errors);
		}

		function parseGateway(location, value, errors) {
			if (type(value) == "string") {
				if (!matchIpv4(value))
					push(errors, [ location, "must be a valid IPv4 address" ]);

			}

			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "gateway")) {
			obj.gateway = parseGateway(location + "/gateway", value["gateway"], errors);
		}

		function parseSendHostname(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "send-hostname")) {
			obj.send_hostname = parseSendHostname(location + "/send-hostname", value["send-hostname"], errors);
		}
		else {
			obj.send_hostname = true;
		}

		function parseUseDns(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					if (type(value) == "string") {
						if (!matchIpv4(value))
							push(errors, [ location, "must be a valid IPv4 address" ]);

					}

					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "use-dns")) {
			obj.use_dns = parseUseDns(location + "/use-dns", value["use-dns"], errors);
		}

		function parseDisallowUpstreamSubnet(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					if (type(value) == "string") {
						if (!matchUcCidr4(value))
							push(errors, [ location, "must be a valid IPv4 CIDR" ]);

					}

					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "disallow-upstream-subnet")) {
			obj.disallow_upstream_subnet = parseDisallowUpstreamSubnet(location + "/disallow-upstream-subnet", value["disallow-upstream-subnet"], errors);
		}

		if (exists(value, "dhcp")) {
			obj.dhcp = instantiateInterfaceIpv4Dhcp(location + "/dhcp", value["dhcp"], errors);
		}

		function parseDhcpLeases(location, value, errors) {
			if (type(value) == "array") {
				return map(value, (item, i) => instantiateInterfaceIpv4DhcpLease(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "dhcp-leases")) {
			obj.dhcp_leases = parseDhcpLeases(location + "/dhcp-leases", value["dhcp-leases"], errors);
		}

		function parsePortForward(location, value, errors) {
			if (type(value) == "array") {
				return map(value, (item, i) => instantiateInterfaceIpv4PortForward(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "port-forward")) {
			obj.port_forward = parsePortForward(location + "/port-forward", value["port-forward"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateInterfaceIpv6Dhcpv6(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseMode(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			if (!(value in [ "hybrid", "stateless", "stateful", "relay" ]))
				push(errors, [ location, "must be one of \"hybrid\", \"stateless\", \"stateful\" or \"relay\"" ]);

			return value;
		}

		if (exists(value, "mode")) {
			obj.mode = parseMode(location + "/mode", value["mode"], errors);
		}

		function parseAnnounceDns(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					if (type(value) == "string") {
						if (!matchIpv6(value))
							push(errors, [ location, "must be a valid IPv6 address" ]);

					}

					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "announce-dns")) {
			obj.announce_dns = parseAnnounceDns(location + "/announce-dns", value["announce-dns"], errors);
		}

		function parseFilterPrefix(location, value, errors) {
			if (type(value) == "string") {
				if (!matchUcCidr6(value))
					push(errors, [ location, "must be a valid IPv6 CIDR" ]);

			}

			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "filter-prefix")) {
			obj.filter_prefix = parseFilterPrefix(location + "/filter-prefix", value["filter-prefix"], errors);
		}
		else {
			obj.filter_prefix = "::/0";
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateInterfaceIpv6PortForward(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseProtocol(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			if (!(value in [ "tcp", "udp", "any" ]))
				push(errors, [ location, "must be one of \"tcp\", \"udp\" or \"any\"" ]);

			return value;
		}

		if (exists(value, "protocol")) {
			obj.protocol = parseProtocol(location + "/protocol", value["protocol"], errors);
		}
		else {
			obj.protocol = "any";
		}

		function parseExternalPort(location, value, errors) {
			if (type(value) in [ "int", "double" ]) {
				if (value > 65535)
					push(errors, [ location, "must be lower than or equal to 65535" ]);

				if (value < 0)
					push(errors, [ location, "must be bigger than or equal to 0" ]);

			}

			if (type(value) == "string") {
				if (!matchUcPortrange(value))
					push(errors, [ location, "must be a valid network port range" ]);

			}

			if (type(value) != "int" && type(value) != "string")
				push(errors, [ location, "must be of type integer or string" ]);

			return value;
		}

		if (exists(value, "external-port")) {
			obj.external_port = parseExternalPort(location + "/external-port", value["external-port"], errors);
		}
		else {
			push(errors, [ location, "is required" ]);
		}

		function parseInternalAddress(location, value, errors) {
			if (type(value) == "string") {
				if (!matchIpv6(value))
					push(errors, [ location, "must be a valid IPv6 address" ]);

			}

			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "internal-address")) {
			obj.internal_address = parseInternalAddress(location + "/internal-address", value["internal-address"], errors);
		}
		else {
			push(errors, [ location, "is required" ]);
		}

		function parseInternalPort(location, value, errors) {
			if (type(value) in [ "int", "double" ]) {
				if (value > 65535)
					push(errors, [ location, "must be lower than or equal to 65535" ]);

				if (value < 0)
					push(errors, [ location, "must be bigger than or equal to 0" ]);

			}

			if (type(value) == "string") {
				if (!matchUcPortrange(value))
					push(errors, [ location, "must be a valid network port range" ]);

			}

			if (type(value) != "int" && type(value) != "string")
				push(errors, [ location, "must be of type integer or string" ]);

			return value;
		}

		if (exists(value, "internal-port")) {
			obj.internal_port = parseInternalPort(location + "/internal-port", value["internal-port"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateInterfaceIpv6TrafficAllow(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseProtocol(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "protocol")) {
			obj.protocol = parseProtocol(location + "/protocol", value["protocol"], errors);
		}
		else {
			obj.protocol = "any";
		}

		function parseSourceAddress(location, value, errors) {
			if (type(value) == "string") {
				if (!matchUcCidr6(value))
					push(errors, [ location, "must be a valid IPv6 CIDR" ]);

			}

			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "source-address")) {
			obj.source_address = parseSourceAddress(location + "/source-address", value["source-address"], errors);
		}
		else {
			obj.source_address = "::/0";
		}

		function parseSourcePorts(location, value, errors) {
			if (type(value) == "array") {
				if (length(value) < 1)
					push(errors, [ location, "must have at least 1 items" ]);

				function parseItem(location, value, errors) {
					if (type(value) in [ "int", "double" ]) {
						if (value > 65535)
							push(errors, [ location, "must be lower than or equal to 65535" ]);

						if (value < 0)
							push(errors, [ location, "must be bigger than or equal to 0" ]);

					}

					if (type(value) == "string") {
						if (!matchUcPortrange(value))
							push(errors, [ location, "must be a valid network port range" ]);

					}

					if (type(value) != "int" && type(value) != "string")
						push(errors, [ location, "must be of type integer or string" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "source-ports")) {
			obj.source_ports = parseSourcePorts(location + "/source-ports", value["source-ports"], errors);
		}

		function parseDestinationAddress(location, value, errors) {
			if (type(value) == "string") {
				if (!matchIpv6(value))
					push(errors, [ location, "must be a valid IPv6 address" ]);

			}

			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "destination-address")) {
			obj.destination_address = parseDestinationAddress(location + "/destination-address", value["destination-address"], errors);
		}
		else {
			push(errors, [ location, "is required" ]);
		}

		function parseDestinationPorts(location, value, errors) {
			if (type(value) == "array") {
				if (length(value) < 1)
					push(errors, [ location, "must have at least 1 items" ]);

				function parseItem(location, value, errors) {
					if (type(value) in [ "int", "double" ]) {
						if (value > 65535)
							push(errors, [ location, "must be lower than or equal to 65535" ]);

						if (value < 0)
							push(errors, [ location, "must be bigger than or equal to 0" ]);

					}

					if (type(value) == "string") {
						if (!matchUcPortrange(value))
							push(errors, [ location, "must be a valid network port range" ]);

					}

					if (type(value) != "int" && type(value) != "string")
						push(errors, [ location, "must be of type integer or string" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "destination-ports")) {
			obj.destination_ports = parseDestinationPorts(location + "/destination-ports", value["destination-ports"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateInterfaceIpv6(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseAddressing(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			if (!(value in [ "dynamic", "static" ]))
				push(errors, [ location, "must be one of \"dynamic\" or \"static\"" ]);

			return value;
		}

		if (exists(value, "addressing")) {
			obj.addressing = parseAddressing(location + "/addressing", value["addressing"], errors);
		}

		function parseSubnet(location, value, errors) {
			if (type(value) == "string") {
				if (!matchUcCidr6(value))
					push(errors, [ location, "must be a valid IPv6 CIDR" ]);

			}

			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "subnet")) {
			obj.subnet = parseSubnet(location + "/subnet", value["subnet"], errors);
		}

		function parseGateway(location, value, errors) {
			if (type(value) == "string") {
				if (!matchIpv6(value))
					push(errors, [ location, "must be a valid IPv6 address" ]);

			}

			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "gateway")) {
			obj.gateway = parseGateway(location + "/gateway", value["gateway"], errors);
		}

		function parsePrefixSize(location, value, errors) {
			if (type(value) in [ "int", "double" ]) {
				if (value > 64)
					push(errors, [ location, "must be lower than or equal to 64" ]);

				if (value < 0)
					push(errors, [ location, "must be bigger than or equal to 0" ]);

			}

			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "prefix-size")) {
			obj.prefix_size = parsePrefixSize(location + "/prefix-size", value["prefix-size"], errors);
		}

		if (exists(value, "dhcpv6")) {
			obj.dhcpv6 = instantiateInterfaceIpv6Dhcpv6(location + "/dhcpv6", value["dhcpv6"], errors);
		}

		function parsePortForward(location, value, errors) {
			if (type(value) == "array") {
				return map(value, (item, i) => instantiateInterfaceIpv6PortForward(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "port-forward")) {
			obj.port_forward = parsePortForward(location + "/port-forward", value["port-forward"], errors);
		}

		function parseTrafficAllow(location, value, errors) {
			if (type(value) == "array") {
				return map(value, (item, i) => instantiateInterfaceIpv6TrafficAllow(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "traffic-allow")) {
			obj.traffic_allow = parseTrafficAllow(location + "/traffic-allow", value["traffic-allow"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateInterfaceBroadBandWwan(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseProtocol(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			if (value != "wwan")
				push(errors, [ location, "must have value \"wwan\"" ]);

			return value;
		}

		if (exists(value, "protocol")) {
			obj.protocol = parseProtocol(location + "/protocol", value["protocol"], errors);
		}

		function parseModemType(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			if (!(value in [ "qmi", "mbim", "wwan" ]))
				push(errors, [ location, "must be one of \"qmi\", \"mbim\" or \"wwan\"" ]);

			return value;
		}

		if (exists(value, "modem-type")) {
			obj.modem_type = parseModemType(location + "/modem-type", value["modem-type"], errors);
		}

		function parseAccessPointName(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "access-point-name")) {
			obj.access_point_name = parseAccessPointName(location + "/access-point-name", value["access-point-name"], errors);
		}

		function parseAuthenticationType(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			if (!(value in [ "none", "pap", "chap", "pap-chap" ]))
				push(errors, [ location, "must be one of \"none\", \"pap\", \"chap\" or \"pap-chap\"" ]);

			return value;
		}

		if (exists(value, "authentication-type")) {
			obj.authentication_type = parseAuthenticationType(location + "/authentication-type", value["authentication-type"], errors);
		}
		else {
			obj.authentication_type = "none";
		}

		function parsePinCode(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "pin-code")) {
			obj.pin_code = parsePinCode(location + "/pin-code", value["pin-code"], errors);
		}

		function parseUserName(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "user-name")) {
			obj.user_name = parseUserName(location + "/user-name", value["user-name"], errors);
		}

		function parsePassword(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "password")) {
			obj.password = parsePassword(location + "/password", value["password"], errors);
		}

		function parsePacketDataProtocol(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			if (!(value in [ "ipv4", "ipv6", "dual-stack" ]))
				push(errors, [ location, "must be one of \"ipv4\", \"ipv6\" or \"dual-stack\"" ]);

			return value;
		}

		if (exists(value, "packet-data-protocol")) {
			obj.packet_data_protocol = parsePacketDataProtocol(location + "/packet-data-protocol", value["packet-data-protocol"], errors);
		}
		else {
			obj.packet_data_protocol = "dual-stack";
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateInterfaceBroadBandPppoe(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseProtocol(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			if (value != "pppoe")
				push(errors, [ location, "must have value \"pppoe\"" ]);

			return value;
		}

		if (exists(value, "protocol")) {
			obj.protocol = parseProtocol(location + "/protocol", value["protocol"], errors);
		}

		function parseUserName(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "user-name")) {
			obj.user_name = parseUserName(location + "/user-name", value["user-name"], errors);
		}

		function parsePassword(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "password")) {
			obj.password = parsePassword(location + "/password", value["password"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateInterfaceBroadBand(location, value, errors) {
	function parseVariant0(location, value, errors) {
		value = instantiateInterfaceBroadBandWwan(location, value, errors);

		return value;
	}

	function parseVariant1(location, value, errors) {
		value = instantiateInterfaceBroadBandPppoe(location, value, errors);

		return value;
	}

	let success = 0, tryval, tryerr, vvalue = null, verrors = [];

	tryerr = [];
	tryval = parseVariant0(location, value, tryerr);
	if (!length(tryerr)) {
		if (type(vvalue) == "object" && type(tryval) == "object")
			vvalue = { ...vvalue, ...tryval };
		else
			vvalue = tryval;

		success++;
	}
	else {
		push(verrors, join(" and\n", map(tryerr, err => "\t - " + err[1])));
	}

	tryerr = [];
	tryval = parseVariant1(location, value, tryerr);
	if (!length(tryerr)) {
		if (type(vvalue) == "object" && type(tryval) == "object")
			vvalue = { ...vvalue, ...tryval };
		else
			vvalue = tryval;

		success++;
	}
	else {
		push(verrors, join(" and\n", map(tryerr, err => "\t - " + err[1])));
	}

	if (success != 1) {
		if (length(verrors))
			push(errors, [ location, "must match exactly one of the following constraints:\n" + join("\n- or -\n", verrors) ]);
		else
			push(errors, [ location, "must match only one variant" ]);
		return null;
	}

	value = vvalue;

	return value;
}

function instantiateInterfaceSsidMultiPsk(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseMac(location, value, errors) {
			if (type(value) == "string") {
				if (!matchUcMac(value))
					push(errors, [ location, "must be a valid MAC address" ]);

			}

			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "mac")) {
			obj.mac = parseMac(location + "/mac", value["mac"], errors);
		}

		function parseKey(location, value, errors) {
			if (type(value) == "string") {
				if (length(value) > 63)
					push(errors, [ location, "must be at most 63 characters long" ]);

				if (length(value) < 8)
					push(errors, [ location, "must be at least 8 characters long" ]);

			}

			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "key")) {
			obj.key = parseKey(location + "/key", value["key"], errors);
		}

		function parseVlanId(location, value, errors) {
			if (type(value) in [ "int", "double" ]) {
				if (value > 4096)
					push(errors, [ location, "must be lower than or equal to 4096" ]);

			}

			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "vlan-id")) {
			obj.vlan_id = parseVlanId(location + "/vlan-id", value["vlan-id"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateInterfaceSsidRrm(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseNeighborReporting(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "neighbor-reporting")) {
			obj.neighbor_reporting = parseNeighborReporting(location + "/neighbor-reporting", value["neighbor-reporting"], errors);
		}
		else {
			obj.neighbor_reporting = false;
		}

		function parseReducedNeighborReporting(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "reduced-neighbor-reporting")) {
			obj.reduced_neighbor_reporting = parseReducedNeighborReporting(location + "/reduced-neighbor-reporting", value["reduced-neighbor-reporting"], errors);
		}
		else {
			obj.reduced_neighbor_reporting = false;
		}

		function parseLci(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "lci")) {
			obj.lci = parseLci(location + "/lci", value["lci"], errors);
		}

		function parseCivicLocation(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "civic-location")) {
			obj.civic_location = parseCivicLocation(location + "/civic-location", value["civic-location"], errors);
		}

		function parseFtmResponder(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "ftm-responder")) {
			obj.ftm_responder = parseFtmResponder(location + "/ftm-responder", value["ftm-responder"], errors);
		}
		else {
			obj.ftm_responder = false;
		}

		function parseStationaryAp(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "stationary-ap")) {
			obj.stationary_ap = parseStationaryAp(location + "/stationary-ap", value["stationary-ap"], errors);
		}
		else {
			obj.stationary_ap = false;
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateInterfaceSsidRateLimit(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseIngressRate(location, value, errors) {
			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "ingress-rate")) {
			obj.ingress_rate = parseIngressRate(location + "/ingress-rate", value["ingress-rate"], errors);
		}
		else {
			obj.ingress_rate = 0;
		}

		function parseEgressRate(location, value, errors) {
			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "egress-rate")) {
			obj.egress_rate = parseEgressRate(location + "/egress-rate", value["egress-rate"], errors);
		}
		else {
			obj.egress_rate = 0;
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateInterfaceSsidRoaming(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseMessageExchange(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			if (!(value in [ "air", "ds" ]))
				push(errors, [ location, "must be one of \"air\" or \"ds\"" ]);

			return value;
		}

		if (exists(value, "message-exchange")) {
			obj.message_exchange = parseMessageExchange(location + "/message-exchange", value["message-exchange"], errors);
		}
		else {
			obj.message_exchange = "ds";
		}

		function parseGeneratePsk(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "generate-psk")) {
			obj.generate_psk = parseGeneratePsk(location + "/generate-psk", value["generate-psk"], errors);
		}
		else {
			obj.generate_psk = false;
		}

		function parseDomainIdentifier(location, value, errors) {
			if (type(value) == "string") {
				if (!matchUcMobility(value))
					push(errors, [ location, "must be a valid Mobility Domain" ]);

			}

			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "domain-identifier")) {
			obj.domain_identifier = parseDomainIdentifier(location + "/domain-identifier", value["domain-identifier"], errors);
		}

		function parsePmkR0KeyHolder(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "pmk-r0-key-holder")) {
			obj.pmk_r0_key_holder = parsePmkR0KeyHolder(location + "/pmk-r0-key-holder", value["pmk-r0-key-holder"], errors);
		}

		function parsePmkR1KeyHolder(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "pmk-r1-key-holder")) {
			obj.pmk_r1_key_holder = parsePmkR1KeyHolder(location + "/pmk-r1-key-holder", value["pmk-r1-key-holder"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateInterfaceSsidRadiusLocalUser(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseMac(location, value, errors) {
			if (type(value) == "string") {
				if (!matchUcMac(value))
					push(errors, [ location, "must be a valid MAC address" ]);

			}

			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "mac")) {
			obj.mac = parseMac(location + "/mac", value["mac"], errors);
		}

		function parseUserName(location, value, errors) {
			if (type(value) == "string") {
				if (length(value) < 1)
					push(errors, [ location, "must be at least 1 characters long" ]);

			}

			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "user-name")) {
			obj.user_name = parseUserName(location + "/user-name", value["user-name"], errors);
		}

		function parsePassword(location, value, errors) {
			if (type(value) == "string") {
				if (length(value) > 63)
					push(errors, [ location, "must be at most 63 characters long" ]);

				if (length(value) < 8)
					push(errors, [ location, "must be at least 8 characters long" ]);

			}

			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "password")) {
			obj.password = parsePassword(location + "/password", value["password"], errors);
		}

		function parseVlanId(location, value, errors) {
			if (type(value) in [ "int", "double" ]) {
				if (value > 4096)
					push(errors, [ location, "must be lower than or equal to 4096" ]);

			}

			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "vlan-id")) {
			obj.vlan_id = parseVlanId(location + "/vlan-id", value["vlan-id"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateInterfaceSsidRadiusLocal(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseServerIdentity(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "server-identity")) {
			obj.server_identity = parseServerIdentity(location + "/server-identity", value["server-identity"], errors);
		}
		else {
			obj.server_identity = "uCentral";
		}

		function parseUsers(location, value, errors) {
			if (type(value) == "array") {
				return map(value, (item, i) => instantiateInterfaceSsidRadiusLocalUser(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "users")) {
			obj.users = parseUsers(location + "/users", value["users"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateInterfaceSsidRadiusServer(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseHost(location, value, errors) {
			if (type(value) == "string") {
				if (!matchUcHost(value))
					push(errors, [ location, "must be a valid hostname or IP address" ]);

			}

			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "host")) {
			obj.host = parseHost(location + "/host", value["host"], errors);
		}

		function parsePort(location, value, errors) {
			if (type(value) in [ "int", "double" ]) {
				if (value > 65535)
					push(errors, [ location, "must be lower than or equal to 65535" ]);

				if (value < 1024)
					push(errors, [ location, "must be bigger than or equal to 1024" ]);

			}

			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "port")) {
			obj.port = parsePort(location + "/port", value["port"], errors);
		}

		function parseSecret(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "secret")) {
			obj.secret = parseSecret(location + "/secret", value["secret"], errors);
		}

		function parseSecondary(location, value, errors) {
			if (type(value) == "object") {
				let obj = {};

				function parseHost(location, value, errors) {
					if (type(value) == "string") {
						if (!matchUcHost(value))
							push(errors, [ location, "must be a valid hostname or IP address" ]);

					}

					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					return value;
				}

				if (exists(value, "host")) {
					obj.host = parseHost(location + "/host", value["host"], errors);
				}

				function parsePort(location, value, errors) {
					if (type(value) in [ "int", "double" ]) {
						if (value > 65535)
							push(errors, [ location, "must be lower than or equal to 65535" ]);

						if (value < 1024)
							push(errors, [ location, "must be bigger than or equal to 1024" ]);

					}

					if (type(value) != "int")
						push(errors, [ location, "must be of type integer" ]);

					return value;
				}

				if (exists(value, "port")) {
					obj.port = parsePort(location + "/port", value["port"], errors);
				}

				function parseSecret(location, value, errors) {
					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					return value;
				}

				if (exists(value, "secret")) {
					obj.secret = parseSecret(location + "/secret", value["secret"], errors);
				}

				return obj;
			}

			if (type(value) != "object")
				push(errors, [ location, "must be of type object" ]);

			return value;
		}

		if (exists(value, "secondary")) {
			obj.secondary = parseSecondary(location + "/secondary", value["secondary"], errors);
		}

		function parseRequestAttribute(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					function parseVariant0(location, value, errors) {
						if (type(value) == "object") {
							let obj = {};

							function parseVendorId(location, value, errors) {
								if (type(value) in [ "int", "double" ]) {
									if (value > 65535)
										push(errors, [ location, "must be lower than or equal to 65535" ]);

									if (value < 1)
										push(errors, [ location, "must be bigger than or equal to 1" ]);

								}

								if (type(value) != "int")
									push(errors, [ location, "must be of type integer" ]);

								return value;
							}

							if (exists(value, "vendor-id")) {
								obj.vendor_id = parseVendorId(location + "/vendor-id", value["vendor-id"], errors);
							}

							function parseVendorAttributes(location, value, errors) {
								if (type(value) == "array") {
									function parseItem(location, value, errors) {
										if (type(value) == "object") {
											let obj = {};

											function parseId(location, value, errors) {
												if (type(value) in [ "int", "double" ]) {
													if (value > 255)
														push(errors, [ location, "must be lower than or equal to 255" ]);

													if (value < 1)
														push(errors, [ location, "must be bigger than or equal to 1" ]);

												}

												if (type(value) != "int")
													push(errors, [ location, "must be of type integer" ]);

												return value;
											}

											if (exists(value, "id")) {
												obj.id = parseId(location + "/id", value["id"], errors);
											}

											function parseValue(location, value, errors) {
												if (type(value) != "string")
													push(errors, [ location, "must be of type string" ]);

												return value;
											}

											if (exists(value, "value")) {
												obj.value = parseValue(location + "/value", value["value"], errors);
											}

											return obj;
										}

										if (type(value) != "object")
											push(errors, [ location, "must be of type object" ]);

										return value;
									}

									return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
								}

								if (type(value) != "array")
									push(errors, [ location, "must be of type array" ]);

								return value;
							}

							if (exists(value, "vendor-attributes")) {
								obj.vendor_attributes = parseVendorAttributes(location + "/vendor-attributes", value["vendor-attributes"], errors);
							}

							return obj;
						}

						if (type(value) != "object")
							push(errors, [ location, "must be of type object" ]);

						return value;
					}

					function parseVariant1(location, value, errors) {
						if (type(value) == "object") {
							let obj = {};

							function parseId(location, value, errors) {
								if (type(value) in [ "int", "double" ]) {
									if (value > 255)
										push(errors, [ location, "must be lower than or equal to 255" ]);

									if (value < 1)
										push(errors, [ location, "must be bigger than or equal to 1" ]);

								}

								if (type(value) != "int")
									push(errors, [ location, "must be of type integer" ]);

								return value;
							}

							if (exists(value, "id")) {
								obj.id = parseId(location + "/id", value["id"], errors);
							}

							function parseValue(location, value, errors) {
								if (type(value) in [ "int", "double" ]) {
									if (value > 4294967295)
										push(errors, [ location, "must be lower than or equal to 4294967295" ]);

									if (value < 0)
										push(errors, [ location, "must be bigger than or equal to 0" ]);

								}

								if (type(value) != "int")
									push(errors, [ location, "must be of type integer" ]);

								return value;
							}

							if (exists(value, "value")) {
								obj.value = parseValue(location + "/value", value["value"], errors);
							}

							return obj;
						}

						if (type(value) != "object")
							push(errors, [ location, "must be of type object" ]);

						return value;
					}

					function parseVariant2(location, value, errors) {
						if (type(value) == "object") {
							let obj = {};

							function parseId(location, value, errors) {
								if (type(value) in [ "int", "double" ]) {
									if (value > 255)
										push(errors, [ location, "must be lower than or equal to 255" ]);

									if (value < 1)
										push(errors, [ location, "must be bigger than or equal to 1" ]);

								}

								if (type(value) != "int")
									push(errors, [ location, "must be of type integer" ]);

								return value;
							}

							if (exists(value, "id")) {
								obj.id = parseId(location + "/id", value["id"], errors);
							}

							function parseValue(location, value, errors) {
								if (type(value) != "string")
									push(errors, [ location, "must be of type string" ]);

								return value;
							}

							if (exists(value, "value")) {
								obj.value = parseValue(location + "/value", value["value"], errors);
							}

							return obj;
						}

						if (type(value) != "object")
							push(errors, [ location, "must be of type object" ]);

						return value;
					}

					function parseVariant3(location, value, errors) {
						if (type(value) == "object") {
							let obj = {};

							function parseId(location, value, errors) {
								if (type(value) in [ "int", "double" ]) {
									if (value > 255)
										push(errors, [ location, "must be lower than or equal to 255" ]);

									if (value < 1)
										push(errors, [ location, "must be bigger than or equal to 1" ]);

								}

								if (type(value) != "int")
									push(errors, [ location, "must be of type integer" ]);

								return value;
							}

							if (exists(value, "id")) {
								obj.id = parseId(location + "/id", value["id"], errors);
							}

							function parseHexValue(location, value, errors) {
								if (type(value) != "string")
									push(errors, [ location, "must be of type string" ]);

								return value;
							}

							if (exists(value, "hex-value")) {
								obj.hex_value = parseHexValue(location + "/hex-value", value["hex-value"], errors);
							}

							return obj;
						}

						if (type(value) != "object")
							push(errors, [ location, "must be of type object" ]);

						return value;
					}

					let success = 0, tryval, tryerr, vvalue = null, verrors = [];

					tryerr = [];
					tryval = parseVariant0(location, value, tryerr);
					if (!length(tryerr)) {
						if (type(vvalue) == "object" && type(tryval) == "object")
							vvalue = { ...vvalue, ...tryval };
						else
							vvalue = tryval;

						success++;
					}
					else {
						push(verrors, join(" and\n", map(tryerr, err => "\t - " + err[1])));
					}

					tryerr = [];
					tryval = parseVariant1(location, value, tryerr);
					if (!length(tryerr)) {
						if (type(vvalue) == "object" && type(tryval) == "object")
							vvalue = { ...vvalue, ...tryval };
						else
							vvalue = tryval;

						success++;
					}
					else {
						push(verrors, join(" and\n", map(tryerr, err => "\t - " + err[1])));
					}

					tryerr = [];
					tryval = parseVariant2(location, value, tryerr);
					if (!length(tryerr)) {
						if (type(vvalue) == "object" && type(tryval) == "object")
							vvalue = { ...vvalue, ...tryval };
						else
							vvalue = tryval;

						success++;
					}
					else {
						push(verrors, join(" and\n", map(tryerr, err => "\t - " + err[1])));
					}

					tryerr = [];
					tryval = parseVariant3(location, value, tryerr);
					if (!length(tryerr)) {
						if (type(vvalue) == "object" && type(tryval) == "object")
							vvalue = { ...vvalue, ...tryval };
						else
							vvalue = tryval;

						success++;
					}
					else {
						push(verrors, join(" and\n", map(tryerr, err => "\t - " + err[1])));
					}

					if (success == 0) {
						if (length(verrors))
							push(errors, [ location, "must match at least one of the following constraints:\n" + join("\n- or -\n", verrors) ]);
						else
							push(errors, [ location, "must match only one variant" ]);
						return null;
					}

					value = vvalue;

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "request-attribute")) {
			obj.request_attribute = parseRequestAttribute(location + "/request-attribute", value["request-attribute"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateInterfaceSsidRadiusHealth(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseUsername(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "username")) {
			obj.username = parseUsername(location + "/username", value["username"], errors);
		}

		function parsePassword(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "password")) {
			obj.password = parsePassword(location + "/password", value["password"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateInterfaceSsidRadius(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseNasIdentifier(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "nas-identifier")) {
			obj.nas_identifier = parseNasIdentifier(location + "/nas-identifier", value["nas-identifier"], errors);
		}

		function parseChargeableUserId(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "chargeable-user-id")) {
			obj.chargeable_user_id = parseChargeableUserId(location + "/chargeable-user-id", value["chargeable-user-id"], errors);
		}
		else {
			obj.chargeable_user_id = false;
		}

		if (exists(value, "local")) {
			obj.local = instantiateInterfaceSsidRadiusLocal(location + "/local", value["local"], errors);
		}

		function parseDynamicAuthorization(location, value, errors) {
			if (type(value) == "object") {
				let obj = {};

				function parseHost(location, value, errors) {
					if (type(value) == "string") {
						if (!matchUcIp(value))
							push(errors, [ location, "must be a valid IPv4 or IPv6 address" ]);

					}

					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					return value;
				}

				if (exists(value, "host")) {
					obj.host = parseHost(location + "/host", value["host"], errors);
				}

				function parsePort(location, value, errors) {
					if (type(value) in [ "int", "double" ]) {
						if (value > 65535)
							push(errors, [ location, "must be lower than or equal to 65535" ]);

						if (value < 1024)
							push(errors, [ location, "must be bigger than or equal to 1024" ]);

					}

					if (type(value) != "int")
						push(errors, [ location, "must be of type integer" ]);

					return value;
				}

				if (exists(value, "port")) {
					obj.port = parsePort(location + "/port", value["port"], errors);
				}

				function parseSecret(location, value, errors) {
					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					return value;
				}

				if (exists(value, "secret")) {
					obj.secret = parseSecret(location + "/secret", value["secret"], errors);
				}

				return obj;
			}

			if (type(value) != "object")
				push(errors, [ location, "must be of type object" ]);

			return value;
		}

		if (exists(value, "dynamic-authorization")) {
			obj.dynamic_authorization = parseDynamicAuthorization(location + "/dynamic-authorization", value["dynamic-authorization"], errors);
		}

		function parseAuthentication(location, value, errors) {
			function parseVariant0(location, value, errors) {
				value = instantiateInterfaceSsidRadiusServer(location, value, errors);

				return value;
			}

			function parseVariant1(location, value, errors) {
				if (type(value) == "object") {
					let obj = {};

					function parseMacFilter(location, value, errors) {
						if (type(value) != "bool")
							push(errors, [ location, "must be of type boolean" ]);

						return value;
					}

					if (exists(value, "mac-filter")) {
						obj.mac_filter = parseMacFilter(location + "/mac-filter", value["mac-filter"], errors);
					}
					else {
						obj.mac_filter = false;
					}

					return obj;
				}

				if (type(value) != "object")
					push(errors, [ location, "must be of type object" ]);

				return value;
			}

			let success = 0, tryval, tryerr, vvalue = null, verrors = [];

			tryerr = [];
			tryval = parseVariant0(location, value, tryerr);
			if (!length(tryerr)) {
				if (type(vvalue) == "object" && type(tryval) == "object")
					vvalue = { ...vvalue, ...tryval };
				else
					vvalue = tryval;

				success++;
			}
			else {
				push(verrors, join(" and\n", map(tryerr, err => "\t - " + err[1])));
			}

			tryerr = [];
			tryval = parseVariant1(location, value, tryerr);
			if (!length(tryerr)) {
				if (type(vvalue) == "object" && type(tryval) == "object")
					vvalue = { ...vvalue, ...tryval };
				else
					vvalue = tryval;

				success++;
			}
			else {
				push(verrors, join(" and\n", map(tryerr, err => "\t - " + err[1])));
			}

			if (success != 2) {
				if (length(verrors))
					push(errors, [ location, "must match all of the following constraints:\n" + join("\n- or -\n", verrors) ]);
				else
					push(errors, [ location, "must match only one variant" ]);
				return null;
			}

			value = vvalue;

			return value;
		}

		if (exists(value, "authentication")) {
			obj.authentication = parseAuthentication(location + "/authentication", value["authentication"], errors);
		}

		function parseAccounting(location, value, errors) {
			function parseVariant0(location, value, errors) {
				value = instantiateInterfaceSsidRadiusServer(location, value, errors);

				return value;
			}

			function parseVariant1(location, value, errors) {
				if (type(value) == "object") {
					let obj = {};

					function parseInterval(location, value, errors) {
						if (type(value) in [ "int", "double" ]) {
							if (value > 600)
								push(errors, [ location, "must be lower than or equal to 600" ]);

							if (value < 60)
								push(errors, [ location, "must be bigger than or equal to 60" ]);

						}

						if (type(value) != "int")
							push(errors, [ location, "must be of type integer" ]);

						return value;
					}

					if (exists(value, "interval")) {
						obj.interval = parseInterval(location + "/interval", value["interval"], errors);
					}
					else {
						obj.interval = 60;
					}

					return obj;
				}

				if (type(value) != "object")
					push(errors, [ location, "must be of type object" ]);

				return value;
			}

			let success = 0, tryval, tryerr, vvalue = null, verrors = [];

			tryerr = [];
			tryval = parseVariant0(location, value, tryerr);
			if (!length(tryerr)) {
				if (type(vvalue) == "object" && type(tryval) == "object")
					vvalue = { ...vvalue, ...tryval };
				else
					vvalue = tryval;

				success++;
			}
			else {
				push(verrors, join(" and\n", map(tryerr, err => "\t - " + err[1])));
			}

			tryerr = [];
			tryval = parseVariant1(location, value, tryerr);
			if (!length(tryerr)) {
				if (type(vvalue) == "object" && type(tryval) == "object")
					vvalue = { ...vvalue, ...tryval };
				else
					vvalue = tryval;

				success++;
			}
			else {
				push(verrors, join(" and\n", map(tryerr, err => "\t - " + err[1])));
			}

			if (success != 2) {
				if (length(verrors))
					push(errors, [ location, "must match all of the following constraints:\n" + join("\n- or -\n", verrors) ]);
				else
					push(errors, [ location, "must match only one variant" ]);
				return null;
			}

			value = vvalue;

			return value;
		}

		if (exists(value, "accounting")) {
			obj.accounting = parseAccounting(location + "/accounting", value["accounting"], errors);
		}

		if (exists(value, "health")) {
			obj.health = instantiateInterfaceSsidRadiusHealth(location + "/health", value["health"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateInterfaceSsidCertificates(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseUseLocalCertificates(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "use-local-certificates")) {
			obj.use_local_certificates = parseUseLocalCertificates(location + "/use-local-certificates", value["use-local-certificates"], errors);
		}
		else {
			obj.use_local_certificates = false;
		}

		function parseCaCertificate(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "ca-certificate")) {
			obj.ca_certificate = parseCaCertificate(location + "/ca-certificate", value["ca-certificate"], errors);
		}

		function parseCertificate(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "certificate")) {
			obj.certificate = parseCertificate(location + "/certificate", value["certificate"], errors);
		}

		function parsePrivateKey(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "private-key")) {
			obj.private_key = parsePrivateKey(location + "/private-key", value["private-key"], errors);
		}

		function parsePrivateKeyPassword(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "private-key-password")) {
			obj.private_key_password = parsePrivateKeyPassword(location + "/private-key-password", value["private-key-password"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateInterfaceSsidPassPoint(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseVenueName(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "venue-name")) {
			obj.venue_name = parseVenueName(location + "/venue-name", value["venue-name"], errors);
		}

		function parseVenueGroup(location, value, errors) {
			if (type(value) in [ "int", "double" ]) {
				if (value > 32)
					push(errors, [ location, "must be lower than or equal to 32" ]);

			}

			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "venue-group")) {
			obj.venue_group = parseVenueGroup(location + "/venue-group", value["venue-group"], errors);
		}

		function parseVenueType(location, value, errors) {
			if (type(value) in [ "int", "double" ]) {
				if (value > 32)
					push(errors, [ location, "must be lower than or equal to 32" ]);

			}

			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "venue-type")) {
			obj.venue_type = parseVenueType(location + "/venue-type", value["venue-type"], errors);
		}

		function parseVenueUrl(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					if (type(value) == "string") {
						if (!matchUri(value))
							push(errors, [ location, "must be a valid URI" ]);

					}

					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "venue-url")) {
			obj.venue_url = parseVenueUrl(location + "/venue-url", value["venue-url"], errors);
		}

		function parseAuthType(location, value, errors) {
			if (type(value) == "string") {
				if (length(value) > 2)
					push(errors, [ location, "must be at most 2 characters long" ]);

				if (length(value) < 2)
					push(errors, [ location, "must be at least 2 characters long" ]);

			}

			if (type(value) == "object") {
				let obj = {};

				function parseType(location, value, errors) {
					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					if (!(value in [ "terms-and-conditions", "online-enrollment", "http-redirection", "dns-redirection" ]))
						push(errors, [ location, "must be one of \"terms-and-conditions\", \"online-enrollment\", \"http-redirection\" or \"dns-redirection\"" ]);

					return value;
				}

				if (exists(value, "type")) {
					obj.type = parseType(location + "/type", value["type"], errors);
				}

				function parseUri(location, value, errors) {
					if (type(value) == "string") {
						if (!matchUri(value))
							push(errors, [ location, "must be a valid URI" ]);

					}

					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					return value;
				}

				if (exists(value, "uri")) {
					obj.uri = parseUri(location + "/uri", value["uri"], errors);
				}

				return obj;
			}

			if (type(value) != "object")
				push(errors, [ location, "must be of type object" ]);

			return value;
		}

		if (exists(value, "auth-type")) {
			obj.auth_type = parseAuthType(location + "/auth-type", value["auth-type"], errors);
		}

		function parseDomainName(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					if (type(value) == "string") {
						if (!matchHostname(value))
							push(errors, [ location, "must be a valid hostname" ]);

					}

					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "domain-name")) {
			obj.domain_name = parseDomainName(location + "/domain-name", value["domain-name"], errors);
		}

		function parseNaiRealm(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "nai-realm")) {
			obj.nai_realm = parseNaiRealm(location + "/nai-realm", value["nai-realm"], errors);
		}

		function parseOsen(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "osen")) {
			obj.osen = parseOsen(location + "/osen", value["osen"], errors);
		}

		function parseAnqpDomain(location, value, errors) {
			if (type(value) in [ "int", "double" ]) {
				if (value > 65535)
					push(errors, [ location, "must be lower than or equal to 65535" ]);

				if (value < 0)
					push(errors, [ location, "must be bigger than or equal to 0" ]);

			}

			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "anqp-domain")) {
			obj.anqp_domain = parseAnqpDomain(location + "/anqp-domain", value["anqp-domain"], errors);
		}

		function parseAnqp3gppCellNet(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "anqp-3gpp-cell-net")) {
			obj.anqp_3gpp_cell_net = parseAnqp3gppCellNet(location + "/anqp-3gpp-cell-net", value["anqp-3gpp-cell-net"], errors);
		}

		function parseFriendlyName(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "friendly-name")) {
			obj.friendly_name = parseFriendlyName(location + "/friendly-name", value["friendly-name"], errors);
		}

		function parseAccessNetworkType(location, value, errors) {
			if (type(value) in [ "int", "double" ]) {
				if (value > 15)
					push(errors, [ location, "must be lower than or equal to 15" ]);

			}

			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "access-network-type")) {
			obj.access_network_type = parseAccessNetworkType(location + "/access-network-type", value["access-network-type"], errors);
		}
		else {
			obj.access_network_type = 0;
		}

		function parseInternet(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "internet")) {
			obj.internet = parseInternet(location + "/internet", value["internet"], errors);
		}
		else {
			obj.internet = true;
		}

		function parseAsra(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "asra")) {
			obj.asra = parseAsra(location + "/asra", value["asra"], errors);
		}
		else {
			obj.asra = false;
		}

		function parseEsr(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "esr")) {
			obj.esr = parseEsr(location + "/esr", value["esr"], errors);
		}
		else {
			obj.esr = false;
		}

		function parseUesa(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "uesa")) {
			obj.uesa = parseUesa(location + "/uesa", value["uesa"], errors);
		}
		else {
			obj.uesa = false;
		}

		function parseHessid(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "hessid")) {
			obj.hessid = parseHessid(location + "/hessid", value["hessid"], errors);
		}

		function parseRoamingConsortium(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "roaming-consortium")) {
			obj.roaming_consortium = parseRoamingConsortium(location + "/roaming-consortium", value["roaming-consortium"], errors);
		}

		function parseDisableDgaf(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "disable-dgaf")) {
			obj.disable_dgaf = parseDisableDgaf(location + "/disable-dgaf", value["disable-dgaf"], errors);
		}
		else {
			obj.disable_dgaf = false;
		}

		function parseIpaddrTypeAvailable(location, value, errors) {
			if (type(value) in [ "int", "double" ]) {
				if (value > 255)
					push(errors, [ location, "must be lower than or equal to 255" ]);

			}

			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "ipaddr-type-available")) {
			obj.ipaddr_type_available = parseIpaddrTypeAvailable(location + "/ipaddr-type-available", value["ipaddr-type-available"], errors);
		}

		function parseConnectionCapability(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "connection-capability")) {
			obj.connection_capability = parseConnectionCapability(location + "/connection-capability", value["connection-capability"], errors);
		}

		function parseIcons(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					if (type(value) == "object") {
						let obj = {};

						function parseWidth(location, value, errors) {
							if (type(value) != "int")
								push(errors, [ location, "must be of type integer" ]);

							return value;
						}

						if (exists(value, "width")) {
							obj.width = parseWidth(location + "/width", value["width"], errors);
						}

						function parseHeight(location, value, errors) {
							if (type(value) != "int")
								push(errors, [ location, "must be of type integer" ]);

							return value;
						}

						if (exists(value, "height")) {
							obj.height = parseHeight(location + "/height", value["height"], errors);
						}

						function parseType(location, value, errors) {
							if (type(value) != "string")
								push(errors, [ location, "must be of type string" ]);

							return value;
						}

						if (exists(value, "type")) {
							obj.type = parseType(location + "/type", value["type"], errors);
						}

						function parseIcon(location, value, errors) {
							if (type(value) == "string") {
								if (!matchUcBase64(value))
									push(errors, [ location, "must be a valid base64 encoded data" ]);

							}

							if (type(value) != "string")
								push(errors, [ location, "must be of type string" ]);

							return value;
						}

						if (exists(value, "icon")) {
							obj.icon = parseIcon(location + "/icon", value["icon"], errors);
						}

						function parseLanguage(location, value, errors) {
							if (type(value) == "string") {
								if (!match(value, regexp("^[a-z][a-z][a-z]$")))
									push(errors, [ location, "must match regular expression /^[a-z][a-z][a-z]$/" ]);

							}

							if (type(value) != "string")
								push(errors, [ location, "must be of type string" ]);

							return value;
						}

						if (exists(value, "language")) {
							obj.language = parseLanguage(location + "/language", value["language"], errors);
						}

						return obj;
					}

					if (type(value) != "object")
						push(errors, [ location, "must be of type object" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "icons")) {
			obj.icons = parseIcons(location + "/icons", value["icons"], errors);
		}

		function parseWanMetrics(location, value, errors) {
			if (type(value) == "object") {
				let obj = {};

				function parseInfo(location, value, errors) {
					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					if (!(value in [ "up", "down", "testing" ]))
						push(errors, [ location, "must be one of \"up\", \"down\" or \"testing\"" ]);

					return value;
				}

				if (exists(value, "info")) {
					obj.info = parseInfo(location + "/info", value["info"], errors);
				}

				function parseDownlink(location, value, errors) {
					if (type(value) != "int")
						push(errors, [ location, "must be of type integer" ]);

					return value;
				}

				if (exists(value, "downlink")) {
					obj.downlink = parseDownlink(location + "/downlink", value["downlink"], errors);
				}

				function parseUplink(location, value, errors) {
					if (type(value) != "int")
						push(errors, [ location, "must be of type integer" ]);

					return value;
				}

				if (exists(value, "uplink")) {
					obj.uplink = parseUplink(location + "/uplink", value["uplink"], errors);
				}

				return obj;
			}

			if (type(value) != "object")
				push(errors, [ location, "must be of type object" ]);

			return value;
		}

		if (exists(value, "wan-metrics")) {
			obj.wan_metrics = parseWanMetrics(location + "/wan-metrics", value["wan-metrics"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateInterfaceSsidQualityThresholds(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseProbeRequestRssi(location, value, errors) {
			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "probe-request-rssi")) {
			obj.probe_request_rssi = parseProbeRequestRssi(location + "/probe-request-rssi", value["probe-request-rssi"], errors);
		}

		function parseAssociationRequestRssi(location, value, errors) {
			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "association-request-rssi")) {
			obj.association_request_rssi = parseAssociationRequestRssi(location + "/association-request-rssi", value["association-request-rssi"], errors);
		}

		function parseClientKickRssi(location, value, errors) {
			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "client-kick-rssi")) {
			obj.client_kick_rssi = parseClientKickRssi(location + "/client-kick-rssi", value["client-kick-rssi"], errors);
		}

		function parseClientKickBanTime(location, value, errors) {
			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "client-kick-ban-time")) {
			obj.client_kick_ban_time = parseClientKickBanTime(location + "/client-kick-ban-time", value["client-kick-ban-time"], errors);
		}
		else {
			obj.client_kick_ban_time = 0;
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateInterfaceSsidAcl(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseMode(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			if (!(value in [ "allow", "deny" ]))
				push(errors, [ location, "must be one of \"allow\" or \"deny\"" ]);

			return value;
		}

		if (exists(value, "mode")) {
			obj.mode = parseMode(location + "/mode", value["mode"], errors);
		}

		function parseMacAddress(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					if (type(value) == "string") {
						if (!matchUcMac(value))
							push(errors, [ location, "must be a valid MAC address" ]);

					}

					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "mac-address")) {
			obj.mac_address = parseMacAddress(location + "/mac-address", value["mac-address"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateServiceCaptiveClick(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseAuthMode(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			if (value != "click-to-continue")
				push(errors, [ location, "must have value \"click-to-continue\"" ]);

			return value;
		}

		if (exists(value, "auth-mode")) {
			obj.auth_mode = parseAuthMode(location + "/auth-mode", value["auth-mode"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateServiceCaptiveRadius(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseAuthMode(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			if (value != "radius")
				push(errors, [ location, "must have value \"radius\"" ]);

			return value;
		}

		if (exists(value, "auth-mode")) {
			obj.auth_mode = parseAuthMode(location + "/auth-mode", value["auth-mode"], errors);
		}

		function parseAuthServer(location, value, errors) {
			if (type(value) == "string") {
				if (!matchUcHost(value))
					push(errors, [ location, "must be a valid hostname or IP address" ]);

			}

			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "auth-server")) {
			obj.auth_server = parseAuthServer(location + "/auth-server", value["auth-server"], errors);
		}

		function parseAuthPort(location, value, errors) {
			if (type(value) in [ "int", "double" ]) {
				if (value > 65535)
					push(errors, [ location, "must be lower than or equal to 65535" ]);

				if (value < 1024)
					push(errors, [ location, "must be bigger than or equal to 1024" ]);

			}

			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "auth-port")) {
			obj.auth_port = parseAuthPort(location + "/auth-port", value["auth-port"], errors);
		}
		else {
			obj.auth_port = 1812;
		}

		function parseAuthSecret(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "auth-secret")) {
			obj.auth_secret = parseAuthSecret(location + "/auth-secret", value["auth-secret"], errors);
		}

		function parseAcctServer(location, value, errors) {
			if (type(value) == "string") {
				if (!matchUcHost(value))
					push(errors, [ location, "must be a valid hostname or IP address" ]);

			}

			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "acct-server")) {
			obj.acct_server = parseAcctServer(location + "/acct-server", value["acct-server"], errors);
		}

		function parseAcctPort(location, value, errors) {
			if (type(value) in [ "int", "double" ]) {
				if (value > 65535)
					push(errors, [ location, "must be lower than or equal to 65535" ]);

				if (value < 1024)
					push(errors, [ location, "must be bigger than or equal to 1024" ]);

			}

			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "acct-port")) {
			obj.acct_port = parseAcctPort(location + "/acct-port", value["acct-port"], errors);
		}
		else {
			obj.acct_port = 1812;
		}

		function parseAcctSecret(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "acct-secret")) {
			obj.acct_secret = parseAcctSecret(location + "/acct-secret", value["acct-secret"], errors);
		}

		function parseAcctInterval(location, value, errors) {
			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "acct-interval")) {
			obj.acct_interval = parseAcctInterval(location + "/acct-interval", value["acct-interval"], errors);
		}
		else {
			obj.acct_interval = 600;
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateServiceCaptiveCredentials(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseAuthMode(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			if (value != "credentials")
				push(errors, [ location, "must have value \"credentials\"" ]);

			return value;
		}

		if (exists(value, "auth-mode")) {
			obj.auth_mode = parseAuthMode(location + "/auth-mode", value["auth-mode"], errors);
		}

		function parseCredentials(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					if (type(value) == "object") {
						let obj = {};

						function parseUsername(location, value, errors) {
							if (type(value) != "string")
								push(errors, [ location, "must be of type string" ]);

							return value;
						}

						if (exists(value, "username")) {
							obj.username = parseUsername(location + "/username", value["username"], errors);
						}

						function parsePassword(location, value, errors) {
							if (type(value) != "string")
								push(errors, [ location, "must be of type string" ]);

							return value;
						}

						if (exists(value, "password")) {
							obj.password = parsePassword(location + "/password", value["password"], errors);
						}

						return obj;
					}

					if (type(value) != "object")
						push(errors, [ location, "must be of type object" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "credentials")) {
			obj.credentials = parseCredentials(location + "/credentials", value["credentials"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateServiceCaptiveUam(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseAuthMode(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			if (value != "uam")
				push(errors, [ location, "must have value \"uam\"" ]);

			return value;
		}

		if (exists(value, "auth-mode")) {
			obj.auth_mode = parseAuthMode(location + "/auth-mode", value["auth-mode"], errors);
		}

		function parseUamPort(location, value, errors) {
			if (type(value) in [ "int", "double" ]) {
				if (value > 65535)
					push(errors, [ location, "must be lower than or equal to 65535" ]);

				if (value < 1024)
					push(errors, [ location, "must be bigger than or equal to 1024" ]);

			}

			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "uam-port")) {
			obj.uam_port = parseUamPort(location + "/uam-port", value["uam-port"], errors);
		}
		else {
			obj.uam_port = 3990;
		}

		function parseUamSecret(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "uam-secret")) {
			obj.uam_secret = parseUamSecret(location + "/uam-secret", value["uam-secret"], errors);
		}

		function parseUamServer(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "uam-server")) {
			obj.uam_server = parseUamServer(location + "/uam-server", value["uam-server"], errors);
		}

		function parseNasid(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "nasid")) {
			obj.nasid = parseNasid(location + "/nasid", value["nasid"], errors);
		}

		function parseNasmac(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "nasmac")) {
			obj.nasmac = parseNasmac(location + "/nasmac", value["nasmac"], errors);
		}

		function parseAuthServer(location, value, errors) {
			if (type(value) == "string") {
				if (!matchUcHost(value))
					push(errors, [ location, "must be a valid hostname or IP address" ]);

			}

			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "auth-server")) {
			obj.auth_server = parseAuthServer(location + "/auth-server", value["auth-server"], errors);
		}

		function parseAuthPort(location, value, errors) {
			if (type(value) in [ "int", "double" ]) {
				if (value > 65535)
					push(errors, [ location, "must be lower than or equal to 65535" ]);

				if (value < 1024)
					push(errors, [ location, "must be bigger than or equal to 1024" ]);

			}

			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "auth-port")) {
			obj.auth_port = parseAuthPort(location + "/auth-port", value["auth-port"], errors);
		}
		else {
			obj.auth_port = 1812;
		}

		function parseAuthSecret(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "auth-secret")) {
			obj.auth_secret = parseAuthSecret(location + "/auth-secret", value["auth-secret"], errors);
		}

		function parseAcctServer(location, value, errors) {
			if (type(value) == "string") {
				if (!matchUcHost(value))
					push(errors, [ location, "must be a valid hostname or IP address" ]);

			}

			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "acct-server")) {
			obj.acct_server = parseAcctServer(location + "/acct-server", value["acct-server"], errors);
		}

		function parseAcctPort(location, value, errors) {
			if (type(value) in [ "int", "double" ]) {
				if (value > 65535)
					push(errors, [ location, "must be lower than or equal to 65535" ]);

				if (value < 1024)
					push(errors, [ location, "must be bigger than or equal to 1024" ]);

			}

			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "acct-port")) {
			obj.acct_port = parseAcctPort(location + "/acct-port", value["acct-port"], errors);
		}
		else {
			obj.acct_port = 1812;
		}

		function parseAcctSecret(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "acct-secret")) {
			obj.acct_secret = parseAcctSecret(location + "/acct-secret", value["acct-secret"], errors);
		}

		function parseAcctInterval(location, value, errors) {
			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "acct-interval")) {
			obj.acct_interval = parseAcctInterval(location + "/acct-interval", value["acct-interval"], errors);
		}
		else {
			obj.acct_interval = 600;
		}

		function parseSsid(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "ssid")) {
			obj.ssid = parseSsid(location + "/ssid", value["ssid"], errors);
		}

		function parseMacFormat(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			if (!(value in [ "aabbccddeeff", "aa-bb-cc-dd-ee-ff", "aa:bb:cc:dd:ee:ff", "AABBCCDDEEFF", "AA:BB:CC:DD:EE:FF", "AA-BB-CC-DD-EE-FF" ]))
				push(errors, [ location, "must be one of \"aabbccddeeff\", \"aa-bb-cc-dd-ee-ff\", \"aa:bb:cc:dd:ee:ff\", \"AABBCCDDEEFF\", \"AA:BB:CC:DD:EE:FF\" or \"AA-BB-CC-DD-EE-FF\"" ]);

			return value;
		}

		if (exists(value, "mac-format")) {
			obj.mac_format = parseMacFormat(location + "/mac-format", value["mac-format"], errors);
		}

		function parseFinalRedirectUrl(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			if (!(value in [ "default", "uam" ]))
				push(errors, [ location, "must be one of \"default\" or \"uam\"" ]);

			return value;
		}

		if (exists(value, "final-redirect-url")) {
			obj.final_redirect_url = parseFinalRedirectUrl(location + "/final-redirect-url", value["final-redirect-url"], errors);
		}

		function parseMacAuth(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "mac-auth")) {
			obj.mac_auth = parseMacAuth(location + "/mac-auth", value["mac-auth"], errors);
		}
		else {
			obj.mac_auth = "default";
		}

		function parseRadiusGwProxy(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "radius-gw-proxy")) {
			obj.radius_gw_proxy = parseRadiusGwProxy(location + "/radius-gw-proxy", value["radius-gw-proxy"], errors);
		}
		else {
			obj.radius_gw_proxy = false;
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateServiceCaptive(location, value, errors) {
	function parseVariant0(location, value, errors) {
		function parseVariant0(location, value, errors) {
			value = instantiateServiceCaptiveClick(location, value, errors);

			return value;
		}

		function parseVariant1(location, value, errors) {
			value = instantiateServiceCaptiveRadius(location, value, errors);

			return value;
		}

		function parseVariant2(location, value, errors) {
			value = instantiateServiceCaptiveCredentials(location, value, errors);

			return value;
		}

		function parseVariant3(location, value, errors) {
			value = instantiateServiceCaptiveUam(location, value, errors);

			return value;
		}

		let success = 0, tryval, tryerr, vvalue = null, verrors = [];

		tryerr = [];
		tryval = parseVariant0(location, value, tryerr);
		if (!length(tryerr)) {
			if (type(vvalue) == "object" && type(tryval) == "object")
				vvalue = { ...vvalue, ...tryval };
			else
				vvalue = tryval;

			success++;
		}
		else {
			push(verrors, join(" and\n", map(tryerr, err => "\t - " + err[1])));
		}

		tryerr = [];
		tryval = parseVariant1(location, value, tryerr);
		if (!length(tryerr)) {
			if (type(vvalue) == "object" && type(tryval) == "object")
				vvalue = { ...vvalue, ...tryval };
			else
				vvalue = tryval;

			success++;
		}
		else {
			push(verrors, join(" and\n", map(tryerr, err => "\t - " + err[1])));
		}

		tryerr = [];
		tryval = parseVariant2(location, value, tryerr);
		if (!length(tryerr)) {
			if (type(vvalue) == "object" && type(tryval) == "object")
				vvalue = { ...vvalue, ...tryval };
			else
				vvalue = tryval;

			success++;
		}
		else {
			push(verrors, join(" and\n", map(tryerr, err => "\t - " + err[1])));
		}

		tryerr = [];
		tryval = parseVariant3(location, value, tryerr);
		if (!length(tryerr)) {
			if (type(vvalue) == "object" && type(tryval) == "object")
				vvalue = { ...vvalue, ...tryval };
			else
				vvalue = tryval;

			success++;
		}
		else {
			push(verrors, join(" and\n", map(tryerr, err => "\t - " + err[1])));
		}

		if (success != 1) {
			if (length(verrors))
				push(errors, [ location, "must match exactly one of the following constraints:\n" + join("\n- or -\n", verrors) ]);
			else
				push(errors, [ location, "must match only one variant" ]);
			return null;
		}

		value = vvalue;

		return value;
	}

	function parseVariant1(location, value, errors) {
		if (type(value) == "object") {
			let obj = {};

			function parseWalledGardenFqdn(location, value, errors) {
				if (type(value) == "array") {
					function parseItem(location, value, errors) {
						if (type(value) != "string")
							push(errors, [ location, "must be of type string" ]);

						return value;
					}

					return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
				}

				if (type(value) != "array")
					push(errors, [ location, "must be of type array" ]);

				return value;
			}

			if (exists(value, "walled-garden-fqdn")) {
				obj.walled_garden_fqdn = parseWalledGardenFqdn(location + "/walled-garden-fqdn", value["walled-garden-fqdn"], errors);
			}

			function parseWalledGardenIpaddr(location, value, errors) {
				if (type(value) == "array") {
					function parseItem(location, value, errors) {
						if (type(value) == "string") {
							if (!matchUcIp(value))
								push(errors, [ location, "must be a valid IPv4 or IPv6 address" ]);

						}

						if (type(value) != "string")
							push(errors, [ location, "must be of type string" ]);

						return value;
					}

					return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
				}

				if (type(value) != "array")
					push(errors, [ location, "must be of type array" ]);

				return value;
			}

			if (exists(value, "walled-garden-ipaddr")) {
				obj.walled_garden_ipaddr = parseWalledGardenIpaddr(location + "/walled-garden-ipaddr", value["walled-garden-ipaddr"], errors);
			}

			function parseWebRoot(location, value, errors) {
				if (type(value) == "string") {
					if (!matchUcBase64(value))
						push(errors, [ location, "must be a valid base64 encoded data" ]);

				}

				if (type(value) != "string")
					push(errors, [ location, "must be of type string" ]);

				return value;
			}

			if (exists(value, "web-root")) {
				obj.web_root = parseWebRoot(location + "/web-root", value["web-root"], errors);
			}

			function parseIdleTimeout(location, value, errors) {
				if (type(value) != "int")
					push(errors, [ location, "must be of type integer" ]);

				return value;
			}

			if (exists(value, "idle-timeout")) {
				obj.idle_timeout = parseIdleTimeout(location + "/idle-timeout", value["idle-timeout"], errors);
			}
			else {
				obj.idle_timeout = 600;
			}

			function parseSessionTimeout(location, value, errors) {
				if (type(value) != "int")
					push(errors, [ location, "must be of type integer" ]);

				return value;
			}

			if (exists(value, "session-timeout")) {
				obj.session_timeout = parseSessionTimeout(location + "/session-timeout", value["session-timeout"], errors);
			}

			return obj;
		}

		if (type(value) != "object")
			push(errors, [ location, "must be of type object" ]);

		return value;
	}

	let success = 0, tryval, tryerr, vvalue = null, verrors = [];

	tryerr = [];
	tryval = parseVariant0(location, value, tryerr);
	if (!length(tryerr)) {
		if (type(vvalue) == "object" && type(tryval) == "object")
			vvalue = { ...vvalue, ...tryval };
		else
			vvalue = tryval;

		success++;
	}
	else {
		push(verrors, join(" and\n", map(tryerr, err => "\t - " + err[1])));
	}

	tryerr = [];
	tryval = parseVariant1(location, value, tryerr);
	if (!length(tryerr)) {
		if (type(vvalue) == "object" && type(tryval) == "object")
			vvalue = { ...vvalue, ...tryval };
		else
			vvalue = tryval;

		success++;
	}
	else {
		push(verrors, join(" and\n", map(tryerr, err => "\t - " + err[1])));
	}

	if (success != 2) {
		if (length(verrors))
			push(errors, [ location, "must match all of the following constraints:\n" + join("\n- or -\n", verrors) ]);
		else
			push(errors, [ location, "must match only one variant" ]);
		return null;
	}

	value = vvalue;

	return value;
}

function instantiateInterfaceSsid(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parsePurpose(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			if (!(value in [ "user-defined", "onboarding-ap", "onboarding-sta" ]))
				push(errors, [ location, "must be one of \"user-defined\", \"onboarding-ap\" or \"onboarding-sta\"" ]);

			return value;
		}

		if (exists(value, "purpose")) {
			obj.purpose = parsePurpose(location + "/purpose", value["purpose"], errors);
		}
		else {
			obj.purpose = "user-defined";
		}

		function parseName(location, value, errors) {
			if (type(value) == "string") {
				if (length(value) > 32)
					push(errors, [ location, "must be at most 32 characters long" ]);

				if (length(value) < 1)
					push(errors, [ location, "must be at least 1 characters long" ]);

			}

			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "name")) {
			obj.name = parseName(location + "/name", value["name"], errors);
		}

		function parseWifiBands(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					if (!(value in [ "2G", "5G", "5G-lower", "5G-upper", "6G" ]))
						push(errors, [ location, "must be one of \"2G\", \"5G\", \"5G-lower\", \"5G-upper\" or \"6G\"" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "wifi-bands")) {
			obj.wifi_bands = parseWifiBands(location + "/wifi-bands", value["wifi-bands"], errors);
		}

		function parseBssMode(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			if (!(value in [ "ap", "sta", "mesh", "wds-ap", "wds-sta", "wds-repeater" ]))
				push(errors, [ location, "must be one of \"ap\", \"sta\", \"mesh\", \"wds-ap\", \"wds-sta\" or \"wds-repeater\"" ]);

			return value;
		}

		if (exists(value, "bss-mode")) {
			obj.bss_mode = parseBssMode(location + "/bss-mode", value["bss-mode"], errors);
		}
		else {
			obj.bss_mode = "ap";
		}

		function parseBssid(location, value, errors) {
			if (type(value) == "string") {
				if (!matchUcMac(value))
					push(errors, [ location, "must be a valid MAC address" ]);

			}

			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "bssid")) {
			obj.bssid = parseBssid(location + "/bssid", value["bssid"], errors);
		}

		function parseHiddenSsid(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "hidden-ssid")) {
			obj.hidden_ssid = parseHiddenSsid(location + "/hidden-ssid", value["hidden-ssid"], errors);
		}

		function parseIsolateClients(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "isolate-clients")) {
			obj.isolate_clients = parseIsolateClients(location + "/isolate-clients", value["isolate-clients"], errors);
		}

		function parseStrictForwarding(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "strict-forwarding")) {
			obj.strict_forwarding = parseStrictForwarding(location + "/strict-forwarding", value["strict-forwarding"], errors);
		}
		else {
			obj.strict_forwarding = false;
		}

		function parsePowerSave(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "power-save")) {
			obj.power_save = parsePowerSave(location + "/power-save", value["power-save"], errors);
		}

		function parseRtsThreshold(location, value, errors) {
			if (type(value) in [ "int", "double" ]) {
				if (value > 65535)
					push(errors, [ location, "must be lower than or equal to 65535" ]);

				if (value < 1)
					push(errors, [ location, "must be bigger than or equal to 1" ]);

			}

			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "rts-threshold")) {
			obj.rts_threshold = parseRtsThreshold(location + "/rts-threshold", value["rts-threshold"], errors);
		}

		function parseBroadcastTime(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "broadcast-time")) {
			obj.broadcast_time = parseBroadcastTime(location + "/broadcast-time", value["broadcast-time"], errors);
		}

		function parseUnicastConversion(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "unicast-conversion")) {
			obj.unicast_conversion = parseUnicastConversion(location + "/unicast-conversion", value["unicast-conversion"], errors);
		}
		else {
			obj.unicast_conversion = true;
		}

		function parseServices(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "services")) {
			obj.services = parseServices(location + "/services", value["services"], errors);
		}

		function parseDtimPeriod(location, value, errors) {
			if (type(value) in [ "int", "double" ]) {
				if (value > 255)
					push(errors, [ location, "must be lower than or equal to 255" ]);

				if (value < 1)
					push(errors, [ location, "must be bigger than or equal to 1" ]);

			}

			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "dtim-period")) {
			obj.dtim_period = parseDtimPeriod(location + "/dtim-period", value["dtim-period"], errors);
		}
		else {
			obj.dtim_period = 2;
		}

		function parseMaximumClients(location, value, errors) {
			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "maximum-clients")) {
			obj.maximum_clients = parseMaximumClients(location + "/maximum-clients", value["maximum-clients"], errors);
		}

		function parseProxyArp(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "proxy-arp")) {
			obj.proxy_arp = parseProxyArp(location + "/proxy-arp", value["proxy-arp"], errors);
		}
		else {
			obj.proxy_arp = true;
		}

		function parseDisassocLowAck(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "disassoc-low-ack")) {
			obj.disassoc_low_ack = parseDisassocLowAck(location + "/disassoc-low-ack", value["disassoc-low-ack"], errors);
		}
		else {
			obj.disassoc_low_ack = false;
		}

		function parseVendorElements(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "vendor-elements")) {
			obj.vendor_elements = parseVendorElements(location + "/vendor-elements", value["vendor-elements"], errors);
		}

		function parseTipInformationElement(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "tip-information-element")) {
			obj.tip_information_element = parseTipInformationElement(location + "/tip-information-element", value["tip-information-element"], errors);
		}
		else {
			obj.tip_information_element = true;
		}

		function parseFilsDiscoveryInterval(location, value, errors) {
			if (type(value) in [ "int", "double" ]) {
				if (value > 20)
					push(errors, [ location, "must be lower than or equal to 20" ]);

			}

			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "fils-discovery-interval")) {
			obj.fils_discovery_interval = parseFilsDiscoveryInterval(location + "/fils-discovery-interval", value["fils-discovery-interval"], errors);
		}
		else {
			obj.fils_discovery_interval = 20;
		}

		if (exists(value, "encryption")) {
			obj.encryption = instantiateInterfaceSsidEncryption(location + "/encryption", value["encryption"], errors);
		}

		function parseMultiPsk(location, value, errors) {
			if (type(value) == "array") {
				return map(value, (item, i) => instantiateInterfaceSsidMultiPsk(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "multi-psk")) {
			obj.multi_psk = parseMultiPsk(location + "/multi-psk", value["multi-psk"], errors);
		}

		if (exists(value, "rrm")) {
			obj.rrm = instantiateInterfaceSsidRrm(location + "/rrm", value["rrm"], errors);
		}

		if (exists(value, "rate-limit")) {
			obj.rate_limit = instantiateInterfaceSsidRateLimit(location + "/rate-limit", value["rate-limit"], errors);
		}

		function parseRoaming(location, value, errors) {
			function parseVariant0(location, value, errors) {
				value = instantiateInterfaceSsidRoaming(location, value, errors);

				return value;
			}

			function parseVariant1(location, value, errors) {
				if (type(value) != "bool")
					push(errors, [ location, "must be of type boolean" ]);

				return value;
			}

			let success = 0, tryval, tryerr, vvalue = null, verrors = [];

			tryerr = [];
			tryval = parseVariant0(location, value, tryerr);
			if (!length(tryerr)) {
				if (type(vvalue) == "object" && type(tryval) == "object")
					vvalue = { ...vvalue, ...tryval };
				else
					vvalue = tryval;

				success++;
			}
			else {
				push(verrors, join(" and\n", map(tryerr, err => "\t - " + err[1])));
			}

			tryerr = [];
			tryval = parseVariant1(location, value, tryerr);
			if (!length(tryerr)) {
				if (type(vvalue) == "object" && type(tryval) == "object")
					vvalue = { ...vvalue, ...tryval };
				else
					vvalue = tryval;

				success++;
			}
			else {
				push(verrors, join(" and\n", map(tryerr, err => "\t - " + err[1])));
			}

			if (success == 0) {
				if (length(verrors))
					push(errors, [ location, "must match at least one of the following constraints:\n" + join("\n- or -\n", verrors) ]);
				else
					push(errors, [ location, "must match only one variant" ]);
				return null;
			}

			value = vvalue;

			return value;
		}

		if (exists(value, "roaming")) {
			obj.roaming = parseRoaming(location + "/roaming", value["roaming"], errors);
		}

		if (exists(value, "radius")) {
			obj.radius = instantiateInterfaceSsidRadius(location + "/radius", value["radius"], errors);
		}

		if (exists(value, "certificates")) {
			obj.certificates = instantiateInterfaceSsidCertificates(location + "/certificates", value["certificates"], errors);
		}

		if (exists(value, "pass-point")) {
			obj.pass_point = instantiateInterfaceSsidPassPoint(location + "/pass-point", value["pass-point"], errors);
		}

		if (exists(value, "quality-thresholds")) {
			obj.quality_thresholds = instantiateInterfaceSsidQualityThresholds(location + "/quality-thresholds", value["quality-thresholds"], errors);
		}

		if (exists(value, "access-control-list")) {
			obj.access_control_list = instantiateInterfaceSsidAcl(location + "/access-control-list", value["access-control-list"], errors);
		}

		if (exists(value, "captive")) {
			obj.captive = instantiateServiceCaptive(location + "/captive", value["captive"], errors);
		}

		function parseVlanAwareness(location, value, errors) {
			if (type(value) == "object") {
				let obj = {};

				function parseFirst(location, value, errors) {
					if (type(value) != "int")
						push(errors, [ location, "must be of type integer" ]);

					return value;
				}

				if (exists(value, "first")) {
					obj.first = parseFirst(location + "/first", value["first"], errors);
				}

				function parseLast(location, value, errors) {
					if (type(value) != "int")
						push(errors, [ location, "must be of type integer" ]);

					return value;
				}

				if (exists(value, "last")) {
					obj.last = parseLast(location + "/last", value["last"], errors);
				}

				return obj;
			}

			if (type(value) != "object")
				push(errors, [ location, "must be of type object" ]);

			return value;
		}

		if (exists(value, "vlan-awareness")) {
			obj.vlan_awareness = parseVlanAwareness(location + "/vlan-awareness", value["vlan-awareness"], errors);
		}

		function parseHostapdBssRaw(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "hostapd-bss-raw")) {
			obj.hostapd_bss_raw = parseHostapdBssRaw(location + "/hostapd-bss-raw", value["hostapd-bss-raw"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateInterfaceTunnelMesh(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseProto(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			if (value != "mesh")
				push(errors, [ location, "must have value \"mesh\"" ]);

			return value;
		}

		if (exists(value, "proto")) {
			obj.proto = parseProto(location + "/proto", value["proto"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateInterfaceTunnelVxlan(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseProto(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			if (value != "vxlan")
				push(errors, [ location, "must have value \"vxlan\"" ]);

			return value;
		}

		if (exists(value, "proto")) {
			obj.proto = parseProto(location + "/proto", value["proto"], errors);
		}

		function parsePeerAddress(location, value, errors) {
			if (type(value) == "string") {
				if (!matchIpv4(value))
					push(errors, [ location, "must be a valid IPv4 address" ]);

			}

			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "peer-address")) {
			obj.peer_address = parsePeerAddress(location + "/peer-address", value["peer-address"], errors);
		}

		function parsePeerPort(location, value, errors) {
			if (type(value) in [ "int", "double" ]) {
				if (value > 65535)
					push(errors, [ location, "must be lower than or equal to 65535" ]);

				if (value < 1)
					push(errors, [ location, "must be bigger than or equal to 1" ]);

			}

			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "peer-port")) {
			obj.peer_port = parsePeerPort(location + "/peer-port", value["peer-port"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateInterfaceTunnelL2tp(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseProto(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			if (value != "l2tp")
				push(errors, [ location, "must have value \"l2tp\"" ]);

			return value;
		}

		if (exists(value, "proto")) {
			obj.proto = parseProto(location + "/proto", value["proto"], errors);
		}

		function parseServer(location, value, errors) {
			if (type(value) == "string") {
				if (!matchIpv4(value))
					push(errors, [ location, "must be a valid IPv4 address" ]);

			}

			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "server")) {
			obj.server = parseServer(location + "/server", value["server"], errors);
		}

		function parseUserName(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "user-name")) {
			obj.user_name = parseUserName(location + "/user-name", value["user-name"], errors);
		}

		function parsePassword(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "password")) {
			obj.password = parsePassword(location + "/password", value["password"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateInterfaceTunnelGre(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseProto(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			if (value != "gre")
				push(errors, [ location, "must have value \"gre\"" ]);

			return value;
		}

		if (exists(value, "proto")) {
			obj.proto = parseProto(location + "/proto", value["proto"], errors);
		}

		function parsePeerAddress(location, value, errors) {
			if (type(value) == "string") {
				if (!matchIpv4(value))
					push(errors, [ location, "must be a valid IPv4 address" ]);

			}

			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "peer-address")) {
			obj.peer_address = parsePeerAddress(location + "/peer-address", value["peer-address"], errors);
		}

		function parseDhcpHealthcheck(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "dhcp-healthcheck")) {
			obj.dhcp_healthcheck = parseDhcpHealthcheck(location + "/dhcp-healthcheck", value["dhcp-healthcheck"], errors);
		}
		else {
			obj.dhcp_healthcheck = false;
		}

		function parseDontFragment(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "dont-fragment")) {
			obj.dont_fragment = parseDontFragment(location + "/dont-fragment", value["dont-fragment"], errors);
		}
		else {
			obj.dont_fragment = false;
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateInterfaceTunnelGre6(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseProto(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			if (value != "gre6")
				push(errors, [ location, "must have value \"gre6\"" ]);

			return value;
		}

		if (exists(value, "proto")) {
			obj.proto = parseProto(location + "/proto", value["proto"], errors);
		}

		function parsePeerAddress(location, value, errors) {
			if (type(value) == "string") {
				if (!matchIpv6(value))
					push(errors, [ location, "must be a valid IPv6 address" ]);

			}

			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "peer-address")) {
			obj.peer_address = parsePeerAddress(location + "/peer-address", value["peer-address"], errors);
		}

		function parseDhcpHealthcheck(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "dhcp-healthcheck")) {
			obj.dhcp_healthcheck = parseDhcpHealthcheck(location + "/dhcp-healthcheck", value["dhcp-healthcheck"], errors);
		}
		else {
			obj.dhcp_healthcheck = false;
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateInterfaceTunnel(location, value, errors) {
	function parseVariant0(location, value, errors) {
		value = instantiateInterfaceTunnelMesh(location, value, errors);

		return value;
	}

	function parseVariant1(location, value, errors) {
		value = instantiateInterfaceTunnelVxlan(location, value, errors);

		return value;
	}

	function parseVariant2(location, value, errors) {
		value = instantiateInterfaceTunnelL2tp(location, value, errors);

		return value;
	}

	function parseVariant3(location, value, errors) {
		value = instantiateInterfaceTunnelGre(location, value, errors);

		return value;
	}

	function parseVariant4(location, value, errors) {
		value = instantiateInterfaceTunnelGre6(location, value, errors);

		return value;
	}

	let success = 0, tryval, tryerr, vvalue = null, verrors = [];

	tryerr = [];
	tryval = parseVariant0(location, value, tryerr);
	if (!length(tryerr)) {
		if (type(vvalue) == "object" && type(tryval) == "object")
			vvalue = { ...vvalue, ...tryval };
		else
			vvalue = tryval;

		success++;
	}
	else {
		push(verrors, join(" and\n", map(tryerr, err => "\t - " + err[1])));
	}

	tryerr = [];
	tryval = parseVariant1(location, value, tryerr);
	if (!length(tryerr)) {
		if (type(vvalue) == "object" && type(tryval) == "object")
			vvalue = { ...vvalue, ...tryval };
		else
			vvalue = tryval;

		success++;
	}
	else {
		push(verrors, join(" and\n", map(tryerr, err => "\t - " + err[1])));
	}

	tryerr = [];
	tryval = parseVariant2(location, value, tryerr);
	if (!length(tryerr)) {
		if (type(vvalue) == "object" && type(tryval) == "object")
			vvalue = { ...vvalue, ...tryval };
		else
			vvalue = tryval;

		success++;
	}
	else {
		push(verrors, join(" and\n", map(tryerr, err => "\t - " + err[1])));
	}

	tryerr = [];
	tryval = parseVariant3(location, value, tryerr);
	if (!length(tryerr)) {
		if (type(vvalue) == "object" && type(tryval) == "object")
			vvalue = { ...vvalue, ...tryval };
		else
			vvalue = tryval;

		success++;
	}
	else {
		push(verrors, join(" and\n", map(tryerr, err => "\t - " + err[1])));
	}

	tryerr = [];
	tryval = parseVariant4(location, value, tryerr);
	if (!length(tryerr)) {
		if (type(vvalue) == "object" && type(tryval) == "object")
			vvalue = { ...vvalue, ...tryval };
		else
			vvalue = tryval;

		success++;
	}
	else {
		push(verrors, join(" and\n", map(tryerr, err => "\t - " + err[1])));
	}

	if (success != 1) {
		if (length(verrors))
			push(errors, [ location, "must match exactly one of the following constraints:\n" + join("\n- or -\n", verrors) ]);
		else
			push(errors, [ location, "must match only one variant" ]);
		return null;
	}

	value = vvalue;

	return value;
}

function instantiateInterface(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseName(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "name")) {
			obj.name = parseName(location + "/name", value["name"], errors);
		}

		function parseRole(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			if (!(value in [ "upstream", "downstream" ]))
				push(errors, [ location, "must be one of \"upstream\" or \"downstream\"" ]);

			return value;
		}

		if (exists(value, "role")) {
			obj.role = parseRole(location + "/role", value["role"], errors);
		}

		function parseIsolateHosts(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "isolate-hosts")) {
			obj.isolate_hosts = parseIsolateHosts(location + "/isolate-hosts", value["isolate-hosts"], errors);
		}

		function parseMetric(location, value, errors) {
			if (type(value) in [ "int", "double" ]) {
				if (value > 4294967295)
					push(errors, [ location, "must be lower than or equal to 4294967295" ]);

				if (value < 0)
					push(errors, [ location, "must be bigger than or equal to 0" ]);

			}

			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "metric")) {
			obj.metric = parseMetric(location + "/metric", value["metric"], errors);
		}

		function parseMtu(location, value, errors) {
			if (type(value) in [ "int", "double" ]) {
				if (value > 1500)
					push(errors, [ location, "must be lower than or equal to 1500" ]);

				if (value < 1280)
					push(errors, [ location, "must be bigger than or equal to 1280" ]);

			}

			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "mtu")) {
			obj.mtu = parseMtu(location + "/mtu", value["mtu"], errors);
		}

		function parseServices(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "services")) {
			obj.services = parseServices(location + "/services", value["services"], errors);
		}

		function parseVlanAwareness(location, value, errors) {
			if (type(value) == "object") {
				let obj = {};

				function parseFirst(location, value, errors) {
					if (type(value) != "int")
						push(errors, [ location, "must be of type integer" ]);

					return value;
				}

				if (exists(value, "first")) {
					obj.first = parseFirst(location + "/first", value["first"], errors);
				}

				function parseLast(location, value, errors) {
					if (type(value) != "int")
						push(errors, [ location, "must be of type integer" ]);

					return value;
				}

				if (exists(value, "last")) {
					obj.last = parseLast(location + "/last", value["last"], errors);
				}

				return obj;
			}

			if (type(value) != "object")
				push(errors, [ location, "must be of type object" ]);

			return value;
		}

		if (exists(value, "vlan-awareness")) {
			obj.vlan_awareness = parseVlanAwareness(location + "/vlan-awareness", value["vlan-awareness"], errors);
		}

		function parseIeee8021xPorts(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "ieee8021x-ports")) {
			obj.ieee8021x_ports = parseIeee8021xPorts(location + "/ieee8021x-ports", value["ieee8021x-ports"], errors);
		}

		if (exists(value, "vlan")) {
			obj.vlan = instantiateInterfaceVlan(location + "/vlan", value["vlan"], errors);
		}

		if (exists(value, "bridge")) {
			obj.bridge = instantiateInterfaceBridge(location + "/bridge", value["bridge"], errors);
		}

		function parseEthernet(location, value, errors) {
			if (type(value) == "array") {
				return map(value, (item, i) => instantiateInterfaceEthernet(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "ethernet")) {
			obj.ethernet = parseEthernet(location + "/ethernet", value["ethernet"], errors);
		}

		if (exists(value, "ipv4")) {
			obj.ipv4 = instantiateInterfaceIpv4(location + "/ipv4", value["ipv4"], errors);
		}

		if (exists(value, "ipv6")) {
			obj.ipv6 = instantiateInterfaceIpv6(location + "/ipv6", value["ipv6"], errors);
		}

		if (exists(value, "broad-band")) {
			obj.broad_band = instantiateInterfaceBroadBand(location + "/broad-band", value["broad-band"], errors);
		}

		function parseSsids(location, value, errors) {
			if (type(value) == "array") {
				return map(value, (item, i) => instantiateInterfaceSsid(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "ssids")) {
			obj.ssids = parseSsids(location + "/ssids", value["ssids"], errors);
		}

		if (exists(value, "tunnel")) {
			obj.tunnel = instantiateInterfaceTunnel(location + "/tunnel", value["tunnel"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateServiceLldp(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseDescribe(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "describe")) {
			obj.describe = parseDescribe(location + "/describe", value["describe"], errors);
		}
		else {
			obj.describe = "uCentral Access Point";
		}

		function parseLocation(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "location")) {
			obj.location = parseLocation(location + "/location", value["location"], errors);
		}
		else {
			obj.location = "uCentral Network";
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateServiceSsh(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parsePort(location, value, errors) {
			if (type(value) in [ "int", "double" ]) {
				if (value > 65535)
					push(errors, [ location, "must be lower than or equal to 65535" ]);

			}

			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "port")) {
			obj.port = parsePort(location + "/port", value["port"], errors);
		}
		else {
			obj.port = 22;
		}

		function parseAuthorizedKeys(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "authorized-keys")) {
			obj.authorized_keys = parseAuthorizedKeys(location + "/authorized-keys", value["authorized-keys"], errors);
		}

		function parsePasswordAuthentication(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "password-authentication")) {
			obj.password_authentication = parsePasswordAuthentication(location + "/password-authentication", value["password-authentication"], errors);
		}
		else {
			obj.password_authentication = true;
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateServiceNtp(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseServers(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					if (type(value) == "string") {
						if (!matchUcHost(value))
							push(errors, [ location, "must be a valid hostname or IP address" ]);

					}

					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "servers")) {
			obj.servers = parseServers(location + "/servers", value["servers"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateServiceMdns(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseEnable(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "enable")) {
			obj.enable = parseEnable(location + "/enable", value["enable"], errors);
		}
		else {
			obj.enable = false;
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateServiceRtty(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseHost(location, value, errors) {
			if (type(value) == "string") {
				if (!matchUcHost(value))
					push(errors, [ location, "must be a valid hostname or IP address" ]);

			}

			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "host")) {
			obj.host = parseHost(location + "/host", value["host"], errors);
		}

		function parsePort(location, value, errors) {
			if (type(value) in [ "int", "double" ]) {
				if (value > 65535)
					push(errors, [ location, "must be lower than or equal to 65535" ]);

			}

			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "port")) {
			obj.port = parsePort(location + "/port", value["port"], errors);
		}
		else {
			obj.port = 5912;
		}

		function parseToken(location, value, errors) {
			if (type(value) == "string") {
				if (length(value) > 32)
					push(errors, [ location, "must be at most 32 characters long" ]);

				if (length(value) < 32)
					push(errors, [ location, "must be at least 32 characters long" ]);

			}

			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "token")) {
			obj.token = parseToken(location + "/token", value["token"], errors);
		}

		function parseMutualTls(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "mutual-tls")) {
			obj.mutual_tls = parseMutualTls(location + "/mutual-tls", value["mutual-tls"], errors);
		}
		else {
			obj.mutual_tls = true;
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateServiceLog(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseHost(location, value, errors) {
			if (type(value) == "string") {
				if (!matchUcHost(value))
					push(errors, [ location, "must be a valid hostname or IP address" ]);

			}

			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "host")) {
			obj.host = parseHost(location + "/host", value["host"], errors);
		}

		function parsePort(location, value, errors) {
			if (type(value) in [ "int", "double" ]) {
				if (value > 65535)
					push(errors, [ location, "must be lower than or equal to 65535" ]);

				if (value < 100)
					push(errors, [ location, "must be bigger than or equal to 100" ]);

			}

			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "port")) {
			obj.port = parsePort(location + "/port", value["port"], errors);
		}

		function parseProto(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			if (!(value in [ "tcp", "udp" ]))
				push(errors, [ location, "must be one of \"tcp\" or \"udp\"" ]);

			return value;
		}

		if (exists(value, "proto")) {
			obj.proto = parseProto(location + "/proto", value["proto"], errors);
		}
		else {
			obj.proto = "udp";
		}

		function parseSize(location, value, errors) {
			if (type(value) in [ "int", "double" ]) {
				if (value < 32)
					push(errors, [ location, "must be bigger than or equal to 32" ]);

			}

			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "size")) {
			obj.size = parseSize(location + "/size", value["size"], errors);
		}
		else {
			obj.size = 1000;
		}

		function parsePriority(location, value, errors) {
			if (type(value) in [ "int", "double" ]) {
				if (value < 0)
					push(errors, [ location, "must be bigger than or equal to 0" ]);

			}

			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "priority")) {
			obj.priority = parsePriority(location + "/priority", value["priority"], errors);
		}
		else {
			obj.priority = 7;
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateServiceHttp(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseHttpPort(location, value, errors) {
			if (type(value) in [ "int", "double" ]) {
				if (value > 65535)
					push(errors, [ location, "must be lower than or equal to 65535" ]);

				if (value < 1)
					push(errors, [ location, "must be bigger than or equal to 1" ]);

			}

			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "http-port")) {
			obj.http_port = parseHttpPort(location + "/http-port", value["http-port"], errors);
		}
		else {
			obj.http_port = 80;
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateServiceIgmp(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseEnable(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "enable")) {
			obj.enable = parseEnable(location + "/enable", value["enable"], errors);
		}
		else {
			obj.enable = false;
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateServiceIeee8021x(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseMode(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			if (!(value in [ "radius", "user" ]))
				push(errors, [ location, "must be one of \"radius\" or \"user\"" ]);

			return value;
		}

		if (exists(value, "mode")) {
			obj.mode = parseMode(location + "/mode", value["mode"], errors);
		}

		function parseSelectPorts(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "select-ports")) {
			obj.select_ports = parseSelectPorts(location + "/select-ports", value["select-ports"], errors);
		}

		function parseUsers(location, value, errors) {
			if (type(value) == "array") {
				return map(value, (item, i) => instantiateInterfaceSsidRadiusLocalUser(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "users")) {
			obj.users = parseUsers(location + "/users", value["users"], errors);
		}

		function parseRadius(location, value, errors) {
			if (type(value) == "object") {
				let obj = {};

				function parseNasIdentifier(location, value, errors) {
					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					return value;
				}

				if (exists(value, "nas-identifier")) {
					obj.nas_identifier = parseNasIdentifier(location + "/nas-identifier", value["nas-identifier"], errors);
				}

				function parseAuthServerAddr(location, value, errors) {
					if (type(value) == "string") {
						if (!matchUcHost(value))
							push(errors, [ location, "must be a valid hostname or IP address" ]);

					}

					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					return value;
				}

				if (exists(value, "auth-server-addr")) {
					obj.auth_server_addr = parseAuthServerAddr(location + "/auth-server-addr", value["auth-server-addr"], errors);
				}

				function parseAuthServerPort(location, value, errors) {
					if (type(value) in [ "int", "double" ]) {
						if (value > 65535)
							push(errors, [ location, "must be lower than or equal to 65535" ]);

						if (value < 1024)
							push(errors, [ location, "must be bigger than or equal to 1024" ]);

					}

					if (type(value) != "int")
						push(errors, [ location, "must be of type integer" ]);

					return value;
				}

				if (exists(value, "auth-server-port")) {
					obj.auth_server_port = parseAuthServerPort(location + "/auth-server-port", value["auth-server-port"], errors);
				}

				function parseAuthServerSecret(location, value, errors) {
					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					return value;
				}

				if (exists(value, "auth-server-secret")) {
					obj.auth_server_secret = parseAuthServerSecret(location + "/auth-server-secret", value["auth-server-secret"], errors);
				}

				function parseAcctServerAddr(location, value, errors) {
					if (type(value) == "string") {
						if (!matchUcHost(value))
							push(errors, [ location, "must be a valid hostname or IP address" ]);

					}

					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					return value;
				}

				if (exists(value, "acct-server-addr")) {
					obj.acct_server_addr = parseAcctServerAddr(location + "/acct-server-addr", value["acct-server-addr"], errors);
				}

				function parseAcctServerPort(location, value, errors) {
					if (type(value) in [ "int", "double" ]) {
						if (value > 65535)
							push(errors, [ location, "must be lower than or equal to 65535" ]);

						if (value < 1024)
							push(errors, [ location, "must be bigger than or equal to 1024" ]);

					}

					if (type(value) != "int")
						push(errors, [ location, "must be of type integer" ]);

					return value;
				}

				if (exists(value, "acct-server-port")) {
					obj.acct_server_port = parseAcctServerPort(location + "/acct-server-port", value["acct-server-port"], errors);
				}

				function parseAcctServerSecret(location, value, errors) {
					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					return value;
				}

				if (exists(value, "acct-server-secret")) {
					obj.acct_server_secret = parseAcctServerSecret(location + "/acct-server-secret", value["acct-server-secret"], errors);
				}

				function parseCoaServerAddr(location, value, errors) {
					if (type(value) == "string") {
						if (!matchUcHost(value))
							push(errors, [ location, "must be a valid hostname or IP address" ]);

					}

					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					return value;
				}

				if (exists(value, "coa-server-addr")) {
					obj.coa_server_addr = parseCoaServerAddr(location + "/coa-server-addr", value["coa-server-addr"], errors);
				}

				function parseCoaServerPort(location, value, errors) {
					if (type(value) in [ "int", "double" ]) {
						if (value > 65535)
							push(errors, [ location, "must be lower than or equal to 65535" ]);

						if (value < 1024)
							push(errors, [ location, "must be bigger than or equal to 1024" ]);

					}

					if (type(value) != "int")
						push(errors, [ location, "must be of type integer" ]);

					return value;
				}

				if (exists(value, "coa-server-port")) {
					obj.coa_server_port = parseCoaServerPort(location + "/coa-server-port", value["coa-server-port"], errors);
				}

				function parseCoaServerSecret(location, value, errors) {
					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					return value;
				}

				if (exists(value, "coa-server-secret")) {
					obj.coa_server_secret = parseCoaServerSecret(location + "/coa-server-secret", value["coa-server-secret"], errors);
				}

				function parseMacAddressBypass(location, value, errors) {
					if (type(value) != "bool")
						push(errors, [ location, "must be of type boolean" ]);

					return value;
				}

				if (exists(value, "mac-address-bypass")) {
					obj.mac_address_bypass = parseMacAddressBypass(location + "/mac-address-bypass", value["mac-address-bypass"], errors);
				}

				return obj;
			}

			if (type(value) != "object")
				push(errors, [ location, "must be of type object" ]);

			return value;
		}

		if (exists(value, "radius")) {
			obj.radius = parseRadius(location + "/radius", value["radius"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateServiceRadiusProxy(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseProxySecret(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "proxy-secret")) {
			obj.proxy_secret = parseProxySecret(location + "/proxy-secret", value["proxy-secret"], errors);
		}
		else {
			obj.proxy_secret = "secret";
		}

		function parseRealms(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					function parseVariant0(location, value, errors) {
						if (type(value) == "object") {
							let obj = {};

							function parseProtocol(location, value, errors) {
								if (type(value) != "string")
									push(errors, [ location, "must be of type string" ]);

								if (!(value in [ "radsec" ]))
									push(errors, [ location, "must be one of \"radsec\"" ]);

								return value;
							}

							if (exists(value, "protocol")) {
								obj.protocol = parseProtocol(location + "/protocol", value["protocol"], errors);
							}
							else {
								obj.protocol = "radsec";
							}

							function parseRealm(location, value, errors) {
								if (type(value) == "array") {
									function parseItem(location, value, errors) {
										if (type(value) != "string")
											push(errors, [ location, "must be of type string" ]);

										return value;
									}

									return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
								}

								if (type(value) != "array")
									push(errors, [ location, "must be of type array" ]);

								return value;
							}

							if (exists(value, "realm")) {
								obj.realm = parseRealm(location + "/realm", value["realm"], errors);
							}

							function parseAutoDiscover(location, value, errors) {
								if (type(value) != "bool")
									push(errors, [ location, "must be of type boolean" ]);

								return value;
							}

							if (exists(value, "auto-discover")) {
								obj.auto_discover = parseAutoDiscover(location + "/auto-discover", value["auto-discover"], errors);
							}
							else {
								obj.auto_discover = false;
							}

							function parseHost(location, value, errors) {
								if (type(value) == "string") {
									if (!matchUcHost(value))
										push(errors, [ location, "must be a valid hostname or IP address" ]);

								}

								if (type(value) != "string")
									push(errors, [ location, "must be of type string" ]);

								return value;
							}

							if (exists(value, "host")) {
								obj.host = parseHost(location + "/host", value["host"], errors);
							}

							function parsePort(location, value, errors) {
								if (type(value) in [ "int", "double" ]) {
									if (value > 65535)
										push(errors, [ location, "must be lower than or equal to 65535" ]);

								}

								if (type(value) != "int")
									push(errors, [ location, "must be of type integer" ]);

								return value;
							}

							if (exists(value, "port")) {
								obj.port = parsePort(location + "/port", value["port"], errors);
							}
							else {
								obj.port = 2083;
							}

							function parseSecret(location, value, errors) {
								if (type(value) != "string")
									push(errors, [ location, "must be of type string" ]);

								return value;
							}

							if (exists(value, "secret")) {
								obj.secret = parseSecret(location + "/secret", value["secret"], errors);
							}

							function parseUseLocalCertificates(location, value, errors) {
								if (type(value) != "bool")
									push(errors, [ location, "must be of type boolean" ]);

								return value;
							}

							if (exists(value, "use-local-certificates")) {
								obj.use_local_certificates = parseUseLocalCertificates(location + "/use-local-certificates", value["use-local-certificates"], errors);
							}
							else {
								obj.use_local_certificates = false;
							}

							function parseCaCertificate(location, value, errors) {
								if (type(value) != "string")
									push(errors, [ location, "must be of type string" ]);

								return value;
							}

							if (exists(value, "ca-certificate")) {
								obj.ca_certificate = parseCaCertificate(location + "/ca-certificate", value["ca-certificate"], errors);
							}

							function parseCertificate(location, value, errors) {
								if (type(value) != "string")
									push(errors, [ location, "must be of type string" ]);

								return value;
							}

							if (exists(value, "certificate")) {
								obj.certificate = parseCertificate(location + "/certificate", value["certificate"], errors);
							}

							function parsePrivateKey(location, value, errors) {
								if (type(value) != "string")
									push(errors, [ location, "must be of type string" ]);

								return value;
							}

							if (exists(value, "private-key")) {
								obj.private_key = parsePrivateKey(location + "/private-key", value["private-key"], errors);
							}

							function parsePrivateKeyPassword(location, value, errors) {
								if (type(value) != "string")
									push(errors, [ location, "must be of type string" ]);

								return value;
							}

							if (exists(value, "private-key-password")) {
								obj.private_key_password = parsePrivateKeyPassword(location + "/private-key-password", value["private-key-password"], errors);
							}

							return obj;
						}

						if (type(value) != "object")
							push(errors, [ location, "must be of type object" ]);

						return value;
					}

					function parseVariant1(location, value, errors) {
						if (type(value) == "object") {
							let obj = {};

							function parseProtocol(location, value, errors) {
								if (type(value) != "string")
									push(errors, [ location, "must be of type string" ]);

								if (!(value in [ "radius" ]))
									push(errors, [ location, "must be one of \"radius\"" ]);

								return value;
							}

							if (exists(value, "protocol")) {
								obj.protocol = parseProtocol(location + "/protocol", value["protocol"], errors);
							}

							function parseRealm(location, value, errors) {
								if (type(value) == "array") {
									function parseItem(location, value, errors) {
										if (type(value) != "string")
											push(errors, [ location, "must be of type string" ]);

										return value;
									}

									return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
								}

								if (type(value) != "array")
									push(errors, [ location, "must be of type array" ]);

								return value;
							}

							if (exists(value, "realm")) {
								obj.realm = parseRealm(location + "/realm", value["realm"], errors);
							}

							function parseAuthServer(location, value, errors) {
								if (type(value) == "string") {
									if (!matchUcHost(value))
										push(errors, [ location, "must be a valid hostname or IP address" ]);

								}

								if (type(value) != "string")
									push(errors, [ location, "must be of type string" ]);

								return value;
							}

							if (exists(value, "auth-server")) {
								obj.auth_server = parseAuthServer(location + "/auth-server", value["auth-server"], errors);
							}

							function parseAuthPort(location, value, errors) {
								if (type(value) in [ "int", "double" ]) {
									if (value > 65535)
										push(errors, [ location, "must be lower than or equal to 65535" ]);

									if (value < 1024)
										push(errors, [ location, "must be bigger than or equal to 1024" ]);

								}

								if (type(value) != "int")
									push(errors, [ location, "must be of type integer" ]);

								return value;
							}

							if (exists(value, "auth-port")) {
								obj.auth_port = parseAuthPort(location + "/auth-port", value["auth-port"], errors);
							}

							function parseAuthSecret(location, value, errors) {
								if (type(value) != "string")
									push(errors, [ location, "must be of type string" ]);

								return value;
							}

							if (exists(value, "auth-secret")) {
								obj.auth_secret = parseAuthSecret(location + "/auth-secret", value["auth-secret"], errors);
							}

							function parseAcctServer(location, value, errors) {
								if (type(value) == "string") {
									if (!matchUcHost(value))
										push(errors, [ location, "must be a valid hostname or IP address" ]);

								}

								if (type(value) != "string")
									push(errors, [ location, "must be of type string" ]);

								return value;
							}

							if (exists(value, "acct-server")) {
								obj.acct_server = parseAcctServer(location + "/acct-server", value["acct-server"], errors);
							}

							function parseAcctPort(location, value, errors) {
								if (type(value) in [ "int", "double" ]) {
									if (value > 65535)
										push(errors, [ location, "must be lower than or equal to 65535" ]);

									if (value < 1024)
										push(errors, [ location, "must be bigger than or equal to 1024" ]);

								}

								if (type(value) != "int")
									push(errors, [ location, "must be of type integer" ]);

								return value;
							}

							if (exists(value, "acct-port")) {
								obj.acct_port = parseAcctPort(location + "/acct-port", value["acct-port"], errors);
							}

							function parseAcctSecret(location, value, errors) {
								if (type(value) != "string")
									push(errors, [ location, "must be of type string" ]);

								return value;
							}

							if (exists(value, "acct-secret")) {
								obj.acct_secret = parseAcctSecret(location + "/acct-secret", value["acct-secret"], errors);
							}

							return obj;
						}

						if (type(value) != "object")
							push(errors, [ location, "must be of type object" ]);

						return value;
					}

					function parseVariant2(location, value, errors) {
						if (type(value) == "object") {
							let obj = {};

							function parseProtocol(location, value, errors) {
								if (type(value) != "string")
									push(errors, [ location, "must be of type string" ]);

								if (!(value in [ "block" ]))
									push(errors, [ location, "must be one of \"block\"" ]);

								return value;
							}

							if (exists(value, "protocol")) {
								obj.protocol = parseProtocol(location + "/protocol", value["protocol"], errors);
							}

							function parseRealm(location, value, errors) {
								if (type(value) == "array") {
									function parseItem(location, value, errors) {
										if (type(value) != "string")
											push(errors, [ location, "must be of type string" ]);

										return value;
									}

									return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
								}

								if (type(value) != "array")
									push(errors, [ location, "must be of type array" ]);

								return value;
							}

							if (exists(value, "realm")) {
								obj.realm = parseRealm(location + "/realm", value["realm"], errors);
							}

							function parseMessage(location, value, errors) {
								if (type(value) == "array") {
									function parseItem(location, value, errors) {
										if (type(value) != "string")
											push(errors, [ location, "must be of type string" ]);

										return value;
									}

									return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
								}

								if (type(value) != "string")
									push(errors, [ location, "must be of type string" ]);

								return value;
							}

							if (exists(value, "message")) {
								obj.message = parseMessage(location + "/message", value["message"], errors);
							}

							return obj;
						}

						if (type(value) != "object")
							push(errors, [ location, "must be of type object" ]);

						return value;
					}

					let success = 0, tryval, tryerr, vvalue = null, verrors = [];

					tryerr = [];
					tryval = parseVariant0(location, value, tryerr);
					if (!length(tryerr)) {
						if (type(vvalue) == "object" && type(tryval) == "object")
							vvalue = { ...vvalue, ...tryval };
						else
							vvalue = tryval;

						success++;
					}
					else {
						push(verrors, join(" and\n", map(tryerr, err => "\t - " + err[1])));
					}

					tryerr = [];
					tryval = parseVariant1(location, value, tryerr);
					if (!length(tryerr)) {
						if (type(vvalue) == "object" && type(tryval) == "object")
							vvalue = { ...vvalue, ...tryval };
						else
							vvalue = tryval;

						success++;
					}
					else {
						push(verrors, join(" and\n", map(tryerr, err => "\t - " + err[1])));
					}

					tryerr = [];
					tryval = parseVariant2(location, value, tryerr);
					if (!length(tryerr)) {
						if (type(vvalue) == "object" && type(tryval) == "object")
							vvalue = { ...vvalue, ...tryval };
						else
							vvalue = tryval;

						success++;
					}
					else {
						push(verrors, join(" and\n", map(tryerr, err => "\t - " + err[1])));
					}

					if (success == 0) {
						if (length(verrors))
							push(errors, [ location, "must match at least one of the following constraints:\n" + join("\n- or -\n", verrors) ]);
						else
							push(errors, [ location, "must match only one variant" ]);
						return null;
					}

					value = vvalue;

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "realms")) {
			obj.realms = parseRealms(location + "/realms", value["realms"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateServiceOnlineCheck(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parsePingHosts(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					if (type(value) == "string") {
						if (!matchUcHost(value))
							push(errors, [ location, "must be a valid hostname or IP address" ]);

					}

					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "ping-hosts")) {
			obj.ping_hosts = parsePingHosts(location + "/ping-hosts", value["ping-hosts"], errors);
		}

		function parseDownloadHosts(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "download-hosts")) {
			obj.download_hosts = parseDownloadHosts(location + "/download-hosts", value["download-hosts"], errors);
		}

		function parseCheckInterval(location, value, errors) {
			if (!(type(value) in [ "int", "double" ]))
				push(errors, [ location, "must be of type number" ]);

			return value;
		}

		if (exists(value, "check-interval")) {
			obj.check_interval = parseCheckInterval(location + "/check-interval", value["check-interval"], errors);
		}
		else {
			obj.check_interval = 60;
		}

		function parseCheckThreshold(location, value, errors) {
			if (!(type(value) in [ "int", "double" ]))
				push(errors, [ location, "must be of type number" ]);

			return value;
		}

		if (exists(value, "check-threshold")) {
			obj.check_threshold = parseCheckThreshold(location + "/check-threshold", value["check-threshold"], errors);
		}
		else {
			obj.check_threshold = 1;
		}

		function parseAction(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					if (!(value in [ "wifi", "leds" ]))
						push(errors, [ location, "must be one of \"wifi\" or \"leds\"" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "action")) {
			obj.action = parseAction(location + "/action", value["action"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateServiceDataPlane(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseIngressFilters(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					if (type(value) == "object") {
						let obj = {};

						function parseName(location, value, errors) {
							if (type(value) != "string")
								push(errors, [ location, "must be of type string" ]);

							return value;
						}

						if (exists(value, "name")) {
							obj.name = parseName(location + "/name", value["name"], errors);
						}

						function parseProgram(location, value, errors) {
							if (type(value) == "string") {
								if (!matchUcBase64(value))
									push(errors, [ location, "must be a valid base64 encoded data" ]);

							}

							if (type(value) != "string")
								push(errors, [ location, "must be of type string" ]);

							return value;
						}

						if (exists(value, "program")) {
							obj.program = parseProgram(location + "/program", value["program"], errors);
						}

						return obj;
					}

					if (type(value) != "object")
						push(errors, [ location, "must be of type object" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "ingress-filters")) {
			obj.ingress_filters = parseIngressFilters(location + "/ingress-filters", value["ingress-filters"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateServiceWifiSteering(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseMode(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			if (!(value in [ "local", "none" ]))
				push(errors, [ location, "must be one of \"local\" or \"none\"" ]);

			return value;
		}

		if (exists(value, "mode")) {
			obj.mode = parseMode(location + "/mode", value["mode"], errors);
		}

		function parseAssocSteering(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "assoc-steering")) {
			obj.assoc_steering = parseAssocSteering(location + "/assoc-steering", value["assoc-steering"], errors);
		}
		else {
			obj.assoc_steering = false;
		}

		function parseRequiredSnr(location, value, errors) {
			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "required-snr")) {
			obj.required_snr = parseRequiredSnr(location + "/required-snr", value["required-snr"], errors);
		}
		else {
			obj.required_snr = 0;
		}

		function parseRequiredProbeSnr(location, value, errors) {
			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "required-probe-snr")) {
			obj.required_probe_snr = parseRequiredProbeSnr(location + "/required-probe-snr", value["required-probe-snr"], errors);
		}
		else {
			obj.required_probe_snr = 0;
		}

		function parseRequiredRoamSnr(location, value, errors) {
			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "required-roam-snr")) {
			obj.required_roam_snr = parseRequiredRoamSnr(location + "/required-roam-snr", value["required-roam-snr"], errors);
		}
		else {
			obj.required_roam_snr = 0;
		}

		function parseLoadKickThreshold(location, value, errors) {
			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "load-kick-threshold")) {
			obj.load_kick_threshold = parseLoadKickThreshold(location + "/load-kick-threshold", value["load-kick-threshold"], errors);
		}
		else {
			obj.load_kick_threshold = 0;
		}

		function parseAutoChannel(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "auto-channel")) {
			obj.auto_channel = parseAutoChannel(location + "/auto-channel", value["auto-channel"], errors);
		}
		else {
			obj.auto_channel = false;
		}

		function parseIpv6(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "ipv6")) {
			obj.ipv6 = parseIpv6(location + "/ipv6", value["ipv6"], errors);
		}
		else {
			obj.ipv6 = false;
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateServiceQualityOfServiceClassSelector(location, value, errors) {
	if (type(value) != "string")
		push(errors, [ location, "must be of type string" ]);

	if (!(value in [ "CS0", "CS1", "CS2", "CS3", "CS4", "CS5", "CS6", "CS7", "AF11", "AF12", "AF13", "AF21", "AF22", "AF23", "AF31", "AF32", "AF33", "AF41", "AF42", "AF43", "DF", "EF", "VA", "LE" ]))
		push(errors, [ location, "must be one of \"CS0\", \"CS1\", \"CS2\", \"CS3\", \"CS4\", \"CS5\", \"CS6\", \"CS7\", \"AF11\", \"AF12\", \"AF13\", \"AF21\", \"AF22\", \"AF23\", \"AF31\", \"AF32\", \"AF33\", \"AF41\", \"AF42\", \"AF43\", \"DF\", \"EF\", \"VA\" or \"LE\"" ]);

	return value;
}

function instantiateServiceQualityOfService(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseSelectPorts(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "select-ports")) {
			obj.select_ports = parseSelectPorts(location + "/select-ports", value["select-ports"], errors);
		}

		function parseBandwidthUp(location, value, errors) {
			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "bandwidth-up")) {
			obj.bandwidth_up = parseBandwidthUp(location + "/bandwidth-up", value["bandwidth-up"], errors);
		}
		else {
			obj.bandwidth_up = 0;
		}

		function parseBandwidthDown(location, value, errors) {
			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "bandwidth-down")) {
			obj.bandwidth_down = parseBandwidthDown(location + "/bandwidth-down", value["bandwidth-down"], errors);
		}
		else {
			obj.bandwidth_down = 0;
		}

		function parseBulkDetection(location, value, errors) {
			if (type(value) == "object") {
				let obj = {};

				if (exists(value, "dscp")) {
					obj.dscp = instantiateServiceQualityOfServiceClassSelector(location + "/dscp", value["dscp"], errors);
				}
				else {
					obj.dscp = "CS0";
				}

				function parsePacketsPerSecond(location, value, errors) {
					if (!(type(value) in [ "int", "double" ]))
						push(errors, [ location, "must be of type number" ]);

					return value;
				}

				if (exists(value, "packets-per-second")) {
					obj.packets_per_second = parsePacketsPerSecond(location + "/packets-per-second", value["packets-per-second"], errors);
				}
				else {
					obj.packets_per_second = 0;
				}

				return obj;
			}

			if (type(value) != "object")
				push(errors, [ location, "must be of type object" ]);

			return value;
		}

		if (exists(value, "bulk-detection")) {
			obj.bulk_detection = parseBulkDetection(location + "/bulk-detection", value["bulk-detection"], errors);
		}

		function parseServices(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "services")) {
			obj.services = parseServices(location + "/services", value["services"], errors);
		}

		function parseClassifier(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					if (type(value) == "object") {
						let obj = {};

						if (exists(value, "dscp")) {
							obj.dscp = instantiateServiceQualityOfServiceClassSelector(location + "/dscp", value["dscp"], errors);
						}
						else {
							obj.dscp = "CS1";
						}

						function parsePorts(location, value, errors) {
							if (type(value) == "array") {
								function parseItem(location, value, errors) {
									if (type(value) == "object") {
										let obj = {};

										function parseProtocol(location, value, errors) {
											if (type(value) != "string")
												push(errors, [ location, "must be of type string" ]);

											if (!(value in [ "any", "tcp", "udp" ]))
												push(errors, [ location, "must be one of \"any\", \"tcp\" or \"udp\"" ]);

											return value;
										}

										if (exists(value, "protocol")) {
											obj.protocol = parseProtocol(location + "/protocol", value["protocol"], errors);
										}
										else {
											obj.protocol = "any";
										}

										function parsePort(location, value, errors) {
											if (type(value) != "int")
												push(errors, [ location, "must be of type integer" ]);

											return value;
										}

										if (exists(value, "port")) {
											obj.port = parsePort(location + "/port", value["port"], errors);
										}

										function parseRangeEnd(location, value, errors) {
											if (type(value) != "int")
												push(errors, [ location, "must be of type integer" ]);

											return value;
										}

										if (exists(value, "range-end")) {
											obj.range_end = parseRangeEnd(location + "/range-end", value["range-end"], errors);
										}

										function parseReclassify(location, value, errors) {
											if (type(value) != "bool")
												push(errors, [ location, "must be of type boolean" ]);

											return value;
										}

										if (exists(value, "reclassify")) {
											obj.reclassify = parseReclassify(location + "/reclassify", value["reclassify"], errors);
										}
										else {
											obj.reclassify = true;
										}

										return obj;
									}

									if (type(value) != "object")
										push(errors, [ location, "must be of type object" ]);

									return value;
								}

								return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
							}

							if (type(value) != "array")
								push(errors, [ location, "must be of type array" ]);

							return value;
						}

						if (exists(value, "ports")) {
							obj.ports = parsePorts(location + "/ports", value["ports"], errors);
						}

						function parseDns(location, value, errors) {
							if (type(value) == "array") {
								function parseItem(location, value, errors) {
									if (type(value) == "object") {
										let obj = {};

										function parseFqdn(location, value, errors) {
											if (type(value) == "string") {
												if (!matchUcFqdn(value))
													push(errors, [ location, "must be a valid fully qualified domain name" ]);

											}

											if (type(value) != "string")
												push(errors, [ location, "must be of type string" ]);

											return value;
										}

										if (exists(value, "fqdn")) {
											obj.fqdn = parseFqdn(location + "/fqdn", value["fqdn"], errors);
										}

										function parseSuffixMatching(location, value, errors) {
											if (type(value) != "bool")
												push(errors, [ location, "must be of type boolean" ]);

											return value;
										}

										if (exists(value, "suffix-matching")) {
											obj.suffix_matching = parseSuffixMatching(location + "/suffix-matching", value["suffix-matching"], errors);
										}
										else {
											obj.suffix_matching = true;
										}

										function parseReclassify(location, value, errors) {
											if (type(value) != "bool")
												push(errors, [ location, "must be of type boolean" ]);

											return value;
										}

										if (exists(value, "reclassify")) {
											obj.reclassify = parseReclassify(location + "/reclassify", value["reclassify"], errors);
										}
										else {
											obj.reclassify = true;
										}

										return obj;
									}

									if (type(value) != "object")
										push(errors, [ location, "must be of type object" ]);

									return value;
								}

								return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
							}

							if (type(value) != "array")
								push(errors, [ location, "must be of type array" ]);

							return value;
						}

						if (exists(value, "dns")) {
							obj.dns = parseDns(location + "/dns", value["dns"], errors);
						}

						return obj;
					}

					if (type(value) != "object")
						push(errors, [ location, "must be of type object" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "classifier")) {
			obj.classifier = parseClassifier(location + "/classifier", value["classifier"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateServiceFacebookWifi(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseVendorId(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "vendor-id")) {
			obj.vendor_id = parseVendorId(location + "/vendor-id", value["vendor-id"], errors);
		}

		function parseGatewayId(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "gateway-id")) {
			obj.gateway_id = parseGatewayId(location + "/gateway-id", value["gateway-id"], errors);
		}

		function parseSecret(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "secret")) {
			obj.secret = parseSecret(location + "/secret", value["secret"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateServiceAirtimeFairness(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseVoiceWeight(location, value, errors) {
			if (!(type(value) in [ "int", "double" ]))
				push(errors, [ location, "must be of type number" ]);

			return value;
		}

		if (exists(value, "voice-weight")) {
			obj.voice_weight = parseVoiceWeight(location + "/voice-weight", value["voice-weight"], errors);
		}
		else {
			obj.voice_weight = 4;
		}

		function parsePacketThreshold(location, value, errors) {
			if (!(type(value) in [ "int", "double" ]))
				push(errors, [ location, "must be of type number" ]);

			return value;
		}

		if (exists(value, "packet-threshold")) {
			obj.packet_threshold = parsePacketThreshold(location + "/packet-threshold", value["packet-threshold"], errors);
		}
		else {
			obj.packet_threshold = 100;
		}

		function parseBulkThreshold(location, value, errors) {
			if (!(type(value) in [ "int", "double" ]))
				push(errors, [ location, "must be of type number" ]);

			return value;
		}

		if (exists(value, "bulk-threshold")) {
			obj.bulk_threshold = parseBulkThreshold(location + "/bulk-threshold", value["bulk-threshold"], errors);
		}
		else {
			obj.bulk_threshold = 50;
		}

		function parsePriorityThreshold(location, value, errors) {
			if (!(type(value) in [ "int", "double" ]))
				push(errors, [ location, "must be of type number" ]);

			return value;
		}

		if (exists(value, "priority-threshold")) {
			obj.priority_threshold = parsePriorityThreshold(location + "/priority-threshold", value["priority-threshold"], errors);
		}
		else {
			obj.priority_threshold = 30;
		}

		function parseWeightNormal(location, value, errors) {
			if (!(type(value) in [ "int", "double" ]))
				push(errors, [ location, "must be of type number" ]);

			return value;
		}

		if (exists(value, "weight-normal")) {
			obj.weight_normal = parseWeightNormal(location + "/weight-normal", value["weight-normal"], errors);
		}
		else {
			obj.weight_normal = 256;
		}

		function parseWeightPriority(location, value, errors) {
			if (!(type(value) in [ "int", "double" ]))
				push(errors, [ location, "must be of type number" ]);

			return value;
		}

		if (exists(value, "weight-priority")) {
			obj.weight_priority = parseWeightPriority(location + "/weight-priority", value["weight-priority"], errors);
		}
		else {
			obj.weight_priority = 394;
		}

		function parseWeightBulk(location, value, errors) {
			if (!(type(value) in [ "int", "double" ]))
				push(errors, [ location, "must be of type number" ]);

			return value;
		}

		if (exists(value, "weight-bulk")) {
			obj.weight_bulk = parseWeightBulk(location + "/weight-bulk", value["weight-bulk"], errors);
		}
		else {
			obj.weight_bulk = 128;
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateServiceWireguardOverlay(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseProto(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			if (value != "wireguard-overlay")
				push(errors, [ location, "must have value \"wireguard-overlay\"" ]);

			return value;
		}

		if (exists(value, "proto")) {
			obj.proto = parseProto(location + "/proto", value["proto"], errors);
		}

		function parsePrivateKey(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "private-key")) {
			obj.private_key = parsePrivateKey(location + "/private-key", value["private-key"], errors);
		}

		function parsePeerPort(location, value, errors) {
			if (type(value) in [ "int", "double" ]) {
				if (value > 65535)
					push(errors, [ location, "must be lower than or equal to 65535" ]);

				if (value < 1)
					push(errors, [ location, "must be bigger than or equal to 1" ]);

			}

			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "peer-port")) {
			obj.peer_port = parsePeerPort(location + "/peer-port", value["peer-port"], errors);
		}
		else {
			obj.peer_port = 3456;
		}

		function parsePeerExchangePort(location, value, errors) {
			if (type(value) in [ "int", "double" ]) {
				if (value > 65535)
					push(errors, [ location, "must be lower than or equal to 65535" ]);

				if (value < 1)
					push(errors, [ location, "must be bigger than or equal to 1" ]);

			}

			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "peer-exchange-port")) {
			obj.peer_exchange_port = parsePeerExchangePort(location + "/peer-exchange-port", value["peer-exchange-port"], errors);
		}
		else {
			obj.peer_exchange_port = 3458;
		}

		function parseRootNode(location, value, errors) {
			if (type(value) == "object") {
				let obj = {};

				function parseKey(location, value, errors) {
					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					return value;
				}

				if (exists(value, "key")) {
					obj.key = parseKey(location + "/key", value["key"], errors);
				}

				function parseEndpoint(location, value, errors) {
					if (type(value) == "string") {
						if (!matchUcIp(value))
							push(errors, [ location, "must be a valid IPv4 or IPv6 address" ]);

					}

					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					return value;
				}

				if (exists(value, "endpoint")) {
					obj.endpoint = parseEndpoint(location + "/endpoint", value["endpoint"], errors);
				}

				function parseIpaddr(location, value, errors) {
					if (type(value) == "array") {
						function parseItem(location, value, errors) {
							if (type(value) == "string") {
								if (!matchUcIp(value))
									push(errors, [ location, "must be a valid IPv4 or IPv6 address" ]);

							}

							if (type(value) != "string")
								push(errors, [ location, "must be of type string" ]);

							return value;
						}

						return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
					}

					if (type(value) != "array")
						push(errors, [ location, "must be of type array" ]);

					return value;
				}

				if (exists(value, "ipaddr")) {
					obj.ipaddr = parseIpaddr(location + "/ipaddr", value["ipaddr"], errors);
				}

				return obj;
			}

			if (type(value) != "object")
				push(errors, [ location, "must be of type object" ]);

			return value;
		}

		if (exists(value, "root-node")) {
			obj.root_node = parseRootNode(location + "/root-node", value["root-node"], errors);
		}

		function parseHosts(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					if (type(value) == "object") {
						let obj = {};

						function parseName(location, value, errors) {
							if (type(value) != "string")
								push(errors, [ location, "must be of type string" ]);

							return value;
						}

						if (exists(value, "name")) {
							obj.name = parseName(location + "/name", value["name"], errors);
						}

						function parseKey(location, value, errors) {
							if (type(value) != "string")
								push(errors, [ location, "must be of type string" ]);

							return value;
						}

						if (exists(value, "key")) {
							obj.key = parseKey(location + "/key", value["key"], errors);
						}

						function parseEndpoint(location, value, errors) {
							if (type(value) == "string") {
								if (!matchUcIp(value))
									push(errors, [ location, "must be a valid IPv4 or IPv6 address" ]);

							}

							if (type(value) != "string")
								push(errors, [ location, "must be of type string" ]);

							return value;
						}

						if (exists(value, "endpoint")) {
							obj.endpoint = parseEndpoint(location + "/endpoint", value["endpoint"], errors);
						}

						function parseSubnet(location, value, errors) {
							if (type(value) == "array") {
								function parseItem(location, value, errors) {
									if (type(value) == "string") {
										if (!matchUcCidr(value))
											push(errors, [ location, "must be a valid IPv4 or IPv6 CIDR" ]);

									}

									if (type(value) != "string")
										push(errors, [ location, "must be of type string" ]);

									return value;
								}

								return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
							}

							if (type(value) != "array")
								push(errors, [ location, "must be of type array" ]);

							return value;
						}

						if (exists(value, "subnet")) {
							obj.subnet = parseSubnet(location + "/subnet", value["subnet"], errors);
						}

						function parseIpaddr(location, value, errors) {
							if (type(value) == "array") {
								function parseItem(location, value, errors) {
									if (type(value) == "string") {
										if (!matchUcIp(value))
											push(errors, [ location, "must be a valid IPv4 or IPv6 address" ]);

									}

									if (type(value) != "string")
										push(errors, [ location, "must be of type string" ]);

									return value;
								}

								return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
							}

							if (type(value) != "array")
								push(errors, [ location, "must be of type array" ]);

							return value;
						}

						if (exists(value, "ipaddr")) {
							obj.ipaddr = parseIpaddr(location + "/ipaddr", value["ipaddr"], errors);
						}

						return obj;
					}

					if (type(value) != "object")
						push(errors, [ location, "must be of type object" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "hosts")) {
			obj.hosts = parseHosts(location + "/hosts", value["hosts"], errors);
		}

		function parseVxlan(location, value, errors) {
			if (type(value) == "object") {
				let obj = {};

				function parsePort(location, value, errors) {
					if (type(value) in [ "int", "double" ]) {
						if (value > 65535)
							push(errors, [ location, "must be lower than or equal to 65535" ]);

						if (value < 1)
							push(errors, [ location, "must be bigger than or equal to 1" ]);

					}

					if (type(value) != "int")
						push(errors, [ location, "must be of type integer" ]);

					return value;
				}

				if (exists(value, "port")) {
					obj.port = parsePort(location + "/port", value["port"], errors);
				}
				else {
					obj.port = 4789;
				}

				function parseMtu(location, value, errors) {
					if (type(value) in [ "int", "double" ]) {
						if (value > 65535)
							push(errors, [ location, "must be lower than or equal to 65535" ]);

						if (value < 256)
							push(errors, [ location, "must be bigger than or equal to 256" ]);

					}

					if (type(value) != "int")
						push(errors, [ location, "must be of type integer" ]);

					return value;
				}

				if (exists(value, "mtu")) {
					obj.mtu = parseMtu(location + "/mtu", value["mtu"], errors);
				}
				else {
					obj.mtu = 1420;
				}

				function parseIsolate(location, value, errors) {
					if (type(value) != "bool")
						push(errors, [ location, "must be of type boolean" ]);

					return value;
				}

				if (exists(value, "isolate")) {
					obj.isolate = parseIsolate(location + "/isolate", value["isolate"], errors);
				}
				else {
					obj.isolate = true;
				}

				return obj;
			}

			if (type(value) != "object")
				push(errors, [ location, "must be of type object" ]);

			return value;
		}

		if (exists(value, "vxlan")) {
			obj.vxlan = parseVxlan(location + "/vxlan", value["vxlan"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateServiceGps(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseAdjustTime(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "adjust-time")) {
			obj.adjust_time = parseAdjustTime(location + "/adjust-time", value["adjust-time"], errors);
		}
		else {
			obj.adjust_time = false;
		}

		function parseBaudRate(location, value, errors) {
			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			if (!(value in [ 2400, 4800, 9600, 19200 ]))
				push(errors, [ location, "must be one of 2400, 4800, 9600 or 19200" ]);

			return value;
		}

		if (exists(value, "baud-rate")) {
			obj.baud_rate = parseBaudRate(location + "/baud-rate", value["baud-rate"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateServiceDhcpRelay(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseSelectPorts(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "select-ports")) {
			obj.select_ports = parseSelectPorts(location + "/select-ports", value["select-ports"], errors);
		}

		function parseVlans(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					if (type(value) == "object") {
						let obj = {};

						function parseVlan(location, value, errors) {
							if (!(type(value) in [ "int", "double" ]))
								push(errors, [ location, "must be of type number" ]);

							return value;
						}

						if (exists(value, "vlan")) {
							obj.vlan = parseVlan(location + "/vlan", value["vlan"], errors);
						}

						function parseRelayServer(location, value, errors) {
							if (type(value) == "string") {
								if (!matchUcIp(value))
									push(errors, [ location, "must be a valid IPv4 or IPv6 address" ]);

							}

							if (type(value) != "string")
								push(errors, [ location, "must be of type string" ]);

							return value;
						}

						if (exists(value, "relay-server")) {
							obj.relay_server = parseRelayServer(location + "/relay-server", value["relay-server"], errors);
						}

						function parseCircuitIdFormat(location, value, errors) {
							if (type(value) != "string")
								push(errors, [ location, "must be of type string" ]);

							if (!(value in [ "vlan-id", "ap-mac", "ssid" ]))
								push(errors, [ location, "must be one of \"vlan-id\", \"ap-mac\" or \"ssid\"" ]);

							return value;
						}

						if (exists(value, "circuit-id-format")) {
							obj.circuit_id_format = parseCircuitIdFormat(location + "/circuit-id-format", value["circuit-id-format"], errors);
						}
						else {
							obj.circuit_id_format = "vlan-id";
						}

						function parseRemoteIdFormat(location, value, errors) {
							if (type(value) != "string")
								push(errors, [ location, "must be of type string" ]);

							if (!(value in [ "vlan-id", "ap-mac", "ssid" ]))
								push(errors, [ location, "must be one of \"vlan-id\", \"ap-mac\" or \"ssid\"" ]);

							return value;
						}

						if (exists(value, "remote-id-format")) {
							obj.remote_id_format = parseRemoteIdFormat(location + "/remote-id-format", value["remote-id-format"], errors);
						}
						else {
							obj.remote_id_format = "ap-mac";
						}

						return obj;
					}

					if (type(value) != "object")
						push(errors, [ location, "must be of type object" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "vlans")) {
			obj.vlans = parseVlans(location + "/vlans", value["vlans"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateServiceAdminUi(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseWifiSsid(location, value, errors) {
			if (type(value) == "string") {
				if (length(value) > 32)
					push(errors, [ location, "must be at most 32 characters long" ]);

				if (length(value) < 1)
					push(errors, [ location, "must be at least 1 characters long" ]);

			}

			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "wifi-ssid")) {
			obj.wifi_ssid = parseWifiSsid(location + "/wifi-ssid", value["wifi-ssid"], errors);
		}
		else {
			obj.wifi_ssid = "Maverick";
		}

		function parseWifiKey(location, value, errors) {
			if (type(value) == "string") {
				if (length(value) > 63)
					push(errors, [ location, "must be at most 63 characters long" ]);

				if (length(value) < 8)
					push(errors, [ location, "must be at least 8 characters long" ]);

			}

			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "wifi-key")) {
			obj.wifi_key = parseWifiKey(location + "/wifi-key", value["wifi-key"], errors);
		}

		function parseWifiBands(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					if (!(value in [ "2G", "5G", "5G-lower", "5G-upper", "6G" ]))
						push(errors, [ location, "must be one of \"2G\", \"5G\", \"5G-lower\", \"5G-upper\" or \"6G\"" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "wifi-bands")) {
			obj.wifi_bands = parseWifiBands(location + "/wifi-bands", value["wifi-bands"], errors);
		}

		function parseOfflineTrigger(location, value, errors) {
			if (!(type(value) in [ "int", "double" ]))
				push(errors, [ location, "must be of type number" ]);

			return value;
		}

		if (exists(value, "offline-trigger")) {
			obj.offline_trigger = parseOfflineTrigger(location + "/offline-trigger", value["offline-trigger"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateServiceRrm(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseBeaconRequestAssoc(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "beacon-request-assoc")) {
			obj.beacon_request_assoc = parseBeaconRequestAssoc(location + "/beacon-request-assoc", value["beacon-request-assoc"], errors);
		}
		else {
			obj.beacon_request_assoc = true;
		}

		function parseStationStatsInterval(location, value, errors) {
			if (!(type(value) in [ "int", "double" ]))
				push(errors, [ location, "must be of type number" ]);

			return value;
		}

		if (exists(value, "station-stats-interval")) {
			obj.station_stats_interval = parseStationStatsInterval(location + "/station-stats-interval", value["station-stats-interval"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateServiceFingerprint(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseMode(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			if (!(value in [ "polled", "final", "raw-data" ]))
				push(errors, [ location, "must be one of \"polled\", \"final\" or \"raw-data\"" ]);

			return value;
		}

		if (exists(value, "mode")) {
			obj.mode = parseMode(location + "/mode", value["mode"], errors);
		}
		else {
			obj.mode = "final";
		}

		function parseMinimumAge(location, value, errors) {
			if (!(type(value) in [ "int", "double" ]))
				push(errors, [ location, "must be of type number" ]);

			return value;
		}

		if (exists(value, "minimum-age")) {
			obj.minimum_age = parseMinimumAge(location + "/minimum-age", value["minimum-age"], errors);
		}
		else {
			obj.minimum_age = 60;
		}

		function parseMaximumAge(location, value, errors) {
			if (!(type(value) in [ "int", "double" ]))
				push(errors, [ location, "must be of type number" ]);

			return value;
		}

		if (exists(value, "maximum-age")) {
			obj.maximum_age = parseMaximumAge(location + "/maximum-age", value["maximum-age"], errors);
		}
		else {
			obj.maximum_age = 60;
		}

		function parsePeriodicity(location, value, errors) {
			if (!(type(value) in [ "int", "double" ]))
				push(errors, [ location, "must be of type number" ]);

			return value;
		}

		if (exists(value, "periodicity")) {
			obj.periodicity = parsePeriodicity(location + "/periodicity", value["periodicity"], errors);
		}
		else {
			obj.periodicity = 600;
		}

		function parseAllowWan(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "allow-wan")) {
			obj.allow_wan = parseAllowWan(location + "/allow-wan", value["allow-wan"], errors);
		}
		else {
			obj.allow_wan = false;
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateService(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		if (exists(value, "lldp")) {
			obj.lldp = instantiateServiceLldp(location + "/lldp", value["lldp"], errors);
		}

		if (exists(value, "ssh")) {
			obj.ssh = instantiateServiceSsh(location + "/ssh", value["ssh"], errors);
		}

		if (exists(value, "ntp")) {
			obj.ntp = instantiateServiceNtp(location + "/ntp", value["ntp"], errors);
		}

		if (exists(value, "mdns")) {
			obj.mdns = instantiateServiceMdns(location + "/mdns", value["mdns"], errors);
		}

		if (exists(value, "rtty")) {
			obj.rtty = instantiateServiceRtty(location + "/rtty", value["rtty"], errors);
		}

		if (exists(value, "log")) {
			obj.log = instantiateServiceLog(location + "/log", value["log"], errors);
		}

		if (exists(value, "http")) {
			obj.http = instantiateServiceHttp(location + "/http", value["http"], errors);
		}

		if (exists(value, "igmp")) {
			obj.igmp = instantiateServiceIgmp(location + "/igmp", value["igmp"], errors);
		}

		if (exists(value, "ieee8021x")) {
			obj.ieee8021x = instantiateServiceIeee8021x(location + "/ieee8021x", value["ieee8021x"], errors);
		}

		if (exists(value, "radius-proxy")) {
			obj.radius_proxy = instantiateServiceRadiusProxy(location + "/radius-proxy", value["radius-proxy"], errors);
		}

		if (exists(value, "online-check")) {
			obj.online_check = instantiateServiceOnlineCheck(location + "/online-check", value["online-check"], errors);
		}

		if (exists(value, "data-plane")) {
			obj.data_plane = instantiateServiceDataPlane(location + "/data-plane", value["data-plane"], errors);
		}

		if (exists(value, "wifi-steering")) {
			obj.wifi_steering = instantiateServiceWifiSteering(location + "/wifi-steering", value["wifi-steering"], errors);
		}

		if (exists(value, "quality-of-service")) {
			obj.quality_of_service = instantiateServiceQualityOfService(location + "/quality-of-service", value["quality-of-service"], errors);
		}

		if (exists(value, "facebook-wifi")) {
			obj.facebook_wifi = instantiateServiceFacebookWifi(location + "/facebook-wifi", value["facebook-wifi"], errors);
		}

		if (exists(value, "airtime-fairness")) {
			obj.airtime_fairness = instantiateServiceAirtimeFairness(location + "/airtime-fairness", value["airtime-fairness"], errors);
		}

		if (exists(value, "wireguard-overlay")) {
			obj.wireguard_overlay = instantiateServiceWireguardOverlay(location + "/wireguard-overlay", value["wireguard-overlay"], errors);
		}

		if (exists(value, "captive")) {
			obj.captive = instantiateServiceCaptive(location + "/captive", value["captive"], errors);
		}

		if (exists(value, "gps")) {
			obj.gps = instantiateServiceGps(location + "/gps", value["gps"], errors);
		}

		if (exists(value, "dhcp-relay")) {
			obj.dhcp_relay = instantiateServiceDhcpRelay(location + "/dhcp-relay", value["dhcp-relay"], errors);
		}

		if (exists(value, "admin-ui")) {
			obj.admin_ui = instantiateServiceAdminUi(location + "/admin-ui", value["admin-ui"], errors);
		}

		if (exists(value, "rrm")) {
			obj.rrm = instantiateServiceRrm(location + "/rrm", value["rrm"], errors);
		}

		if (exists(value, "fingerprint")) {
			obj.fingerprint = instantiateServiceFingerprint(location + "/fingerprint", value["fingerprint"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateMetricsStatistics(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseInterval(location, value, errors) {
			if (type(value) in [ "int", "double" ]) {
				if (value < 60)
					push(errors, [ location, "must be bigger than or equal to 60" ]);

			}

			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "interval")) {
			obj.interval = parseInterval(location + "/interval", value["interval"], errors);
		}

		function parseTypes(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					if (!(value in [ "ssids", "lldp", "clients", "tid-stats" ]))
						push(errors, [ location, "must be one of \"ssids\", \"lldp\", \"clients\" or \"tid-stats\"" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "types")) {
			obj.types = parseTypes(location + "/types", value["types"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateMetricsHealth(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseInterval(location, value, errors) {
			if (type(value) in [ "int", "double" ]) {
				if (value < 60)
					push(errors, [ location, "must be bigger than or equal to 60" ]);

			}

			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "interval")) {
			obj.interval = parseInterval(location + "/interval", value["interval"], errors);
		}

		function parseDhcpLocal(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "dhcp-local")) {
			obj.dhcp_local = parseDhcpLocal(location + "/dhcp-local", value["dhcp-local"], errors);
		}
		else {
			obj.dhcp_local = true;
		}

		function parseDhcpRemote(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "dhcp-remote")) {
			obj.dhcp_remote = parseDhcpRemote(location + "/dhcp-remote", value["dhcp-remote"], errors);
		}
		else {
			obj.dhcp_remote = false;
		}

		function parseDnsLocal(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "dns-local")) {
			obj.dns_local = parseDnsLocal(location + "/dns-local", value["dns-local"], errors);
		}
		else {
			obj.dns_local = true;
		}

		function parseDnsRemote(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "dns-remote")) {
			obj.dns_remote = parseDnsRemote(location + "/dns-remote", value["dns-remote"], errors);
		}
		else {
			obj.dns_remote = true;
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateMetricsWifiFrames(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseFilters(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					if (!(value in [ "probe", "auth", "assoc", "disassoc", "deauth", "local-deauth", "inactive-deauth", "key-mismatch", "beacon-report", "radar-detected" ]))
						push(errors, [ location, "must be one of \"probe\", \"auth\", \"assoc\", \"disassoc\", \"deauth\", \"local-deauth\", \"inactive-deauth\", \"key-mismatch\", \"beacon-report\" or \"radar-detected\"" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "filters")) {
			obj.filters = parseFilters(location + "/filters", value["filters"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateMetricsDhcpSnooping(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseFilters(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					if (!(value in [ "ack", "discover", "offer", "request", "solicit", "reply", "renew" ]))
						push(errors, [ location, "must be one of \"ack\", \"discover\", \"offer\", \"request\", \"solicit\", \"reply\" or \"renew\"" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "filters")) {
			obj.filters = parseFilters(location + "/filters", value["filters"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateMetricsWifiScan(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseInterval(location, value, errors) {
			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "interval")) {
			obj.interval = parseInterval(location + "/interval", value["interval"], errors);
		}

		function parseVerbose(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "verbose")) {
			obj.verbose = parseVerbose(location + "/verbose", value["verbose"], errors);
		}

		function parseInformationElements(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "information-elements")) {
			obj.information_elements = parseInformationElements(location + "/information-elements", value["information-elements"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateMetricsTelemetry(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseInterval(location, value, errors) {
			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "interval")) {
			obj.interval = parseInterval(location + "/interval", value["interval"], errors);
		}

		function parseTypes(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					if (!(value in [ "ssh", "health", "health.dns", "health.dhcp", "health.radius", "health.memory", "client", "client.join", "client.leave", "client.key-mismatch", "wifi", "wifi.start", "wifi.stop", "wired", "wired.carrier-up", "wired.carrier-down", "unit", "unit.boot-up" ]))
						push(errors, [ location, "must be one of \"ssh\", \"health\", \"health.dns\", \"health.dhcp\", \"health.radius\", \"health.memory\", \"client\", \"client.join\", \"client.leave\", \"client.key-mismatch\", \"wifi\", \"wifi.start\", \"wifi.stop\", \"wired\", \"wired.carrier-up\", \"wired.carrier-down\", \"unit\" or \"unit.boot-up\"" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "types")) {
			obj.types = parseTypes(location + "/types", value["types"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateMetricsRealtime(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseTypes(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					if (!(value in [ "ssh", "health", "health.dns", "health.dhcp", "health.radius", "health.memory", "client", "client.join", "client.leave", "client.key-mismatch", "wifi", "wifi.start", "wifi.stop", "wired", "wired.carrier-up", "wired.carrier-down", "unit", "unit.boot-up" ]))
						push(errors, [ location, "must be one of \"ssh\", \"health\", \"health.dns\", \"health.dhcp\", \"health.radius\", \"health.memory\", \"client\", \"client.join\", \"client.leave\", \"client.key-mismatch\", \"wifi\", \"wifi.start\", \"wifi.stop\", \"wired\", \"wired.carrier-up\", \"wired.carrier-down\", \"unit\" or \"unit.boot-up\"" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "types")) {
			obj.types = parseTypes(location + "/types", value["types"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateMetrics(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		if (exists(value, "statistics")) {
			obj.statistics = instantiateMetricsStatistics(location + "/statistics", value["statistics"], errors);
		}

		if (exists(value, "health")) {
			obj.health = instantiateMetricsHealth(location + "/health", value["health"], errors);
		}

		if (exists(value, "wifi-frames")) {
			obj.wifi_frames = instantiateMetricsWifiFrames(location + "/wifi-frames", value["wifi-frames"], errors);
		}

		if (exists(value, "dhcp-snooping")) {
			obj.dhcp_snooping = instantiateMetricsDhcpSnooping(location + "/dhcp-snooping", value["dhcp-snooping"], errors);
		}

		if (exists(value, "wifi-scan")) {
			obj.wifi_scan = instantiateMetricsWifiScan(location + "/wifi-scan", value["wifi-scan"], errors);
		}

		if (exists(value, "telemetry")) {
			obj.telemetry = instantiateMetricsTelemetry(location + "/telemetry", value["telemetry"], errors);
		}

		if (exists(value, "realtime")) {
			obj.realtime = instantiateMetricsRealtime(location + "/realtime", value["realtime"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

function instantiateConfigRaw(location, value, errors) {
	if (type(value) == "array") {
		function parseItem(location, value, errors) {
			if (type(value) == "array") {
				if (length(value) < 2)
					push(errors, [ location, "must have at least 2 items" ]);

				function parseItem(location, value, errors) {
					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
	}

	if (type(value) != "array")
		push(errors, [ location, "must be of type array" ]);

	return value;
}

function newUCentralState(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseStrict(location, value, errors) {
			if (type(value) != "bool")
				push(errors, [ location, "must be of type boolean" ]);

			return value;
		}

		if (exists(value, "strict")) {
			obj.strict = parseStrict(location + "/strict", value["strict"], errors);
		}
		else {
			obj.strict = false;
		}

		function parseUuid(location, value, errors) {
			if (type(value) != "int")
				push(errors, [ location, "must be of type integer" ]);

			return value;
		}

		if (exists(value, "uuid")) {
			obj.uuid = parseUuid(location + "/uuid", value["uuid"], errors);
		}

		if (exists(value, "unit")) {
			obj.unit = instantiateUnit(location + "/unit", value["unit"], errors);
		}

		if (exists(value, "globals")) {
			obj.globals = instantiateGlobals(location + "/globals", value["globals"], errors);
		}

		if (exists(value, "definitions")) {
			obj.definitions = instantiateDefinitions(location + "/definitions", value["definitions"], errors);
		}

		function parseEthernet(location, value, errors) {
			if (type(value) == "array") {
				return map(value, (item, i) => instantiateEthernet(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "ethernet")) {
			obj.ethernet = parseEthernet(location + "/ethernet", value["ethernet"], errors);
		}

		if (exists(value, "switch")) {
			obj.switch = instantiateSwitch(location + "/switch", value["switch"], errors);
		}

		function parseRadios(location, value, errors) {
			if (type(value) == "array") {
				return map(value, (item, i) => instantiateRadio(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "radios")) {
			obj.radios = parseRadios(location + "/radios", value["radios"], errors);
		}

		function parseInterfaces(location, value, errors) {
			if (type(value) == "array") {
				return map(value, (item, i) => instantiateInterface(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "interfaces")) {
			obj.interfaces = parseInterfaces(location + "/interfaces", value["interfaces"], errors);
		}

		if (exists(value, "services")) {
			obj.services = instantiateService(location + "/services", value["services"], errors);
		}

		if (exists(value, "metrics")) {
			obj.metrics = instantiateMetrics(location + "/metrics", value["metrics"], errors);
		}

		if (exists(value, "config-raw")) {
			obj.config_raw = instantiateConfigRaw(location + "/config-raw", value["config-raw"], errors);
		}

		function parseThirdParty(location, value, errors) {
			if (type(value) == "object") {
				let obj = { ...value };

				return obj;
			}

			if (type(value) != "object")
				push(errors, [ location, "must be of type object" ]);

			return value;
		}

		if (exists(value, "third-party")) {
			obj.third_party = parseThirdParty(location + "/third-party", value["third-party"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

return {
	validate: (value, errors) => {
		let err = [];
		let res = newUCentralState("", value, err);
		if (errors) push(errors, ...map(err, e => "[E] (In " + e[0] + ") Value " + e[1]));
		return length(err) ? null : res;
	}
};
