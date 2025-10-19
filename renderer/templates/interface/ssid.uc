{%
	// Constants
	const PURPOSE_CONFIGS = {
		"onboarding-ap": {
			"name": "OpenWifi-onboarding",
			"isolate_clients": true,
			"hidden": true,
			"wifi_bands": ["2G"],
			"bss_mode": "ap",
			"encryption": {
				"proto": "wpa2",
				"ieee80211w": "required"
			},
			"certificates": {
				"use_local_certificates": true
			},
			"radius": {
				"local": {
					"server-identity": "uCentral-EAP"
				}
			}
		},
		"onboarding-sta": {
			"name": "OpenWifi-onboarding",
			"wifi_bands": ["2G"],
			"bss_mode": "sta",
			"encryption": {
				"proto": "wpa2",
				"ieee80211w": "required"
			},
			"certificates": {
				"use_local_certificates": true
			}
		}
	};

	const BAND_CRYPTO_RESTRICTIONS = {
		"6G": ["wpa3", "wpa3-mixed", "wpa3-192", "sae", "sae-mixed", "owe", "mpsk-radius"],
		"HaLow": ["sae", "sae-mixed", "owe"]
	};

	const WPA_PROTOCOLS = ["wpa", "wpa2", "wpa-mixed", "wpa3", "wpa3-mixed", "wpa3-192", "psk2-radius", "mpsk-radius"];
	const SAE_PROTOCOLS = ["wpa3", "wpa3-mixed", "wpa3-192", "sae", "sae-mixed"];
	const PSK_PROTOCOLS = ["psk", "psk2", "psk-mixed", "sae", "sae-mixed"];

	const HS20_AUTH_TYPES = {
		"terms-and-conditions": "00",
		"online-enrollment": "01",
		"http-redirection": "02",
		"dns-redirection": "03"
	};

	const WAN_METRICS_STATUS = {
		"up": 1,
		"down": 2,
		"testing": 3
	};

	// Helper functions

	// has_ functions - check for existence/availability
	function has_multi_psk() {
		return (ssid?.encryption.proto == "mpsk-radius") || ssid.multi_psk;
	}

	function has_captive_service() {
		return 'captive' in ssid.services;
	}

	function has_radius_gw_proxy() {
		return ssid.services && (index(ssid.services, "radius-gw-proxy") >= 0);
	}

	function has_pass_point() {
		return !!ssid.pass_point;
	}

	function has_roaming() {
		return !!ssid.roaming;
	}

	function has_rate_limit() {
		return ssid.rate_limit && (ssid.rate_limit.ingress_rate || ssid.rate_limit.egress_rate);
	}

	// is_ functions - boolean checks/validation
	function is_6g_band(band) {
		return band == "6G";
	}

	function is_halow_band(band) {
		return band == "HaLow";
	}

	function is_mesh_mode(mode) {
		return mode == 'mesh';
	}

	function is_ap_sta_mode(mode) {
		return index(['ap', 'sta'], mode) >= 0;
	}

	// match_ functions - value mapping/selection
	function match_wds() {
		return index(["wds-ap", "wds-sta", "wds-repeater"], ssid.bss_mode) >= 0;
	}

	// normalize_ functions - data transformation
	function normalize_roaming_config() {
		if (type(ssid.roaming) == 'bool') {
			ssid.roaming = {
				message_exchange: 'air',
				generate_psk: !has_multi_psk(),
			};
		}

		if (ssid.encryption.proto in SAE_PROTOCOLS) {
			if (ssid.roaming?.generate_psk)
				ssid.roaming.generate_psk = false;
		}

		if (ssid.roaming && ssid.encryption.proto in ["wpa", "psk", "none"]) {
			delete ssid.roaming;
			warn("Roaming requires wpa2 or later");
		}

		if (ssid.roaming?.key_aes_256) {
			delete ssid.roaming.generate_psk;
			delete ssid.roaming.pmk_r0_key_holder;
			delete ssid.roaming.pmk_r1_key_holder;
		}
	}

	function normalize_certificates() {
		let certs = ssid.certificates || {};
		if (certs.use_local_certificates) {
			cursor.load("system");
			let local_certs = cursor.get_all("system", "@certificates[-1]");
			certs.ca_certificate = local_certs.ca;
			certs.certificate = local_certs.cert;
			certs.private_key = local_certs.key;
		}
		return certs;
	}

	function normalize_radius_dynamic_auth() {
		if (ssid.radius?.dynamic_authorization && has_radius_gw_proxy()) {
			ssid.radius.dynamic_authorization.host = '127.0.0.1';
			ssid.radius.dynamic_authorization.port = 3799;
		}
	}

	function normalize_vendor_elements() {
		ssid.vendor_elements ??= '';

		if (ssid.tip_information_element) {
			if (state.unit?.beacon_advertisement) {
				if (state.unit.beacon_advertisement.device_serial)
					ssid.vendor_elements += 'dd1048d01701' + replace(serial, /./g, (m) => sprintf("%02x", ord(m)));
				if (state.unit.beacon_advertisement.device_name && state.unit.name)
					ssid.vendor_elements += 'dd' + sprintf('%02x', 4 + length(state.unit.name)) + '48d01702' + replace(state.unit.name, /./g, (m) => sprintf("%02x", ord(m)));
				if (state.unit.beacon_advertisement.network_id) {
					let id = sprintf('%d', state.unit.beacon_advertisement.network_id);
					ssid.vendor_elements += 'dd' + sprintf('%02x', 4 + length(id)) + '48d01703' + replace(id, /./g, (m) => sprintf("%02x", ord(m)));
				}
			} else {
				ssid.vendor_elements += 'dd0448d01700';
			}
		}
	}

	// Variables declaration (declare early for function access)
	let certificates;

	// Setup and validation
	if (PURPOSE_CONFIGS[ssid.purpose])
		ssid = PURPOSE_CONFIGS[ssid.purpose];

	// Early variable assignments needed for validation
	certificates = normalize_certificates();

	let phys = [];
	for (let band in ssid.wifi_bands) {
		for (let phy in wiphy.lookup_by_band(band)) {
			if (phy.section)
				push(phys, phy);
		}
	}

	if (!length(phys)) {
		warn("Can't find any suitable radio phy for SSID '%s' settings", ssid.name);
		return;
	}

	// validate_ functions - complex validation logic
	function validate_encryption_ap() {
		if (ssid.encryption.proto in WPA_PROTOCOLS &&
		    ssid.radius && ssid.radius.local &&
		    length(certificates))
			return {
				proto: ssid.encryption.proto,
				eap_local: ssid.radius.local,
				eap_user: "/tmp/ucentral/" + replace(location, "/", "_") + ".eap_user"
			};

		if (ssid.encryption.proto in WPA_PROTOCOLS &&
		    ssid.radius && ssid.radius.authentication &&
		    ssid.radius.authentication.host &&
		    ssid.radius.authentication.port &&
		    ssid.radius.authentication.secret)
			return {
				proto: ssid.encryption.proto,
				auth: ssid.radius.authentication,
				acct: ssid.radius.accounting,
				health: ssid.radius.health || {},
				dyn_auth: ssid.radius?.dynamic_authorization,
				radius: ssid.radius
			};
		warn("Can't find any valid encryption settings");
		return false;
	}

	function validate_encryption_sta() {
		if (ssid.encryption.proto in WPA_PROTOCOLS &&
		    length(certificates))
			return {
				proto: ssid.encryption.proto,
				client_tls: certificates
			};
		warn("Can't find any valid encryption settings");
		return false;
	}

	function validate_encryption(band) {
		let is6gband = band == "6G" ? true : false;
		if (is6gband && !(ssid?.encryption.proto in BAND_CRYPTO_RESTRICTIONS["6G"])) {
			warn("Invalid encryption settings for 6G band ");
			return null;
		}

		if (band == "HaLow" && !(ssid?.encryption.proto in BAND_CRYPTO_RESTRICTIONS["HaLow"])) {
			warn("Invalid encryption settings for HaLow band ");
			return null;
		}

		if (!ssid.encryption || ssid.encryption.proto in [ "none" ]) {
			if (ssid.radius?.authentication?.mac_filter &&
			    ssid.radius.authentication?.host &&
			    ssid.radius.authentication?.port &&
			    ssid.radius.authentication?.secret)
				return {
					proto: 'none',
					auth: ssid.radius.authentication,
					acct: ssid.radius.accounting,
					dyn_auth: ssid.radius?.dynamic_authorization,
					health: ssid.radius.health || {},
					radius: ssid.radius
				};
			return {
				proto: 'none',
				dyn_auth: ssid.radius?.dynamic_authorization,
			};
		}

		if (ssid?.encryption?.proto in [ "owe", "owe-transition" ])
			return {
				proto: 'owe'
			};

		let multi_psk = ssid?.encryption.proto == "mpsk-radius";
		if (multi_psk)
			ssid.multi_psk = true;

		let mpsk_6g = is6gband && multi_psk;
		if ((ssid.encryption.proto in PSK_PROTOCOLS || mpsk_6g) &&
		    ssid.encryption.key) {
			if (ssid.radius?.authentication?.mac_filter &&
			    ssid.radius.authentication?.host &&
			    ssid.radius.authentication?.port &&
			    ssid.radius.authentication?.secret)
				return {
					proto: ssid.encryption.proto,
					key: ssid.encryption.key,
					auth: ssid.radius.authentication,
					acct: ssid.radius.accounting,
					dyn_auth: ssid.radius?.dynamic_authorization,
					health: ssid.radius.health || {},
					radius: ssid.radius
				};

			return {
				proto: ssid.encryption.proto,
				key: ssid.encryption.key,
				dyn_auth: ssid.radius?.dynamic_authorization,
				acct: ssid.radius?.accounting,
			};
		};

		switch(ssid.bss_mode) {
		case 'ap':
		case 'wds-ap':
			return validate_encryption_ap();

		case 'sta':
		case 'wds-sta':
			return validate_encryption_sta();

		}
		warn("Can't find any valid encryption settings");
	}

	function match_crypto(band) {
		let crypto = validate_encryption(band);

		if ('6G' == band || 'HaLow' == band) {
			if (crypto.proto == "sae-mixed" || crypto.proto == "mpsk-radius")
				crypto.proto = "sae";
			else if (crypto.proto == "wpa3-mixed")
				crypto.proto = "wpa3";
		} else if (crypto.proto == "mpsk-radius")
			crypto.proto = "psk2-radius";
		return crypto;
	}

	function match_ieee80211w(band) {
		if (band == "6G")
			return 2;

		if (!ssid.encryption || ssid.encryption.proto in ["none"])
			return 0;

		if (ssid.encryption.proto in SAE_PROTOCOLS)
			return 2;

		return index(["disabled", "optional", "required"], ssid.encryption.ieee80211w);
	}

	function match_sae_pwe(band) {
		if (band == "6G")
			return 1;
		return '';
	}

	function match_wds() {
		return index([ "wds-ap", "wds-sta", "wds-repeater" ], ssid.bss_mode) >= 0;
	}

	function match_hs20_auth_type(auth_type) {
		return (auth_type && auth_type.type) ? HS20_AUTH_TYPES[auth_type.type] : '';
	}

	function get_hs20_wan_metrics() {
		if (!ssid.pass_point.wan_metrics ||
		    !ssid.pass_point.wan_metrics.info ||
		    !ssid.pass_point.wan_metrics.downlink ||
		    !ssid.pass_point.wan_metrics.uplink)
			return '';

		let info = WAN_METRICS_STATUS[ssid.pass_point.wan_metrics.info] || 1;
		return sprintf("%02d:%d:%d:0:0:0", info, ssid.pass_point.wan_metrics.downlink, ssid.pass_point.wan_metrics.uplink);
	}

	// normalize_ functions - data transformation
	function normalize_bss_mode() {
		if (ssid.bss_mode == "wds-ap")
			return "ap";
		if (ssid.bss_mode == "wds-sta")
			return "sta";
		return ssid.bss_mode;
	}

	let bss_mode = normalize_bss_mode();

	// Utility functions
	function radius_vendor_tlv(server, port) {
		let radius_serial = replace(serial, /^(..)(..)(..)(..)(..)(..)$/, "$1-$2-$3-$4-$5-$6");
		let radius_serial_len = length(radius_serial) + 2;
		let radius_vendor = "26:x:0000e608" + // vendor element
			"0113" + replace(radius_serial, /./g, (m) => sprintf("%02x", ord(m)));

		let radius_ip = sprintf("%s:%s", server, port);
		let radius_ip_len = length(radius_ip) + 2;
		radius_vendor += "02" + sprintf("%02x", radius_ip_len) + replace(radius_ip, /./g, (m) => sprintf("%02x", ord(m)));
		return radius_vendor;
	}

	function radius_proxy_tlv(server, port, name) {
		let tlv = "33:x:" +
			replace(replace(serial, /^(..)(..)(..)(..)(..)(..)$/, "$1$2$3$4$5$6") + sprintf(":%s:%s:%s", server, port, name),
				/./g, (m) => sprintf("%02x", ord(m)));
		return tlv;
	}

	function radius_request_attribute(request) {
		if (request.id && request.hex_value)
			return sprintf('%d:x:%s', request.id, request.hex_value);
		if (request.id && type(request.value) == 'string')
			return sprintf('%d:s:%s', request.id, request.value);
		if (request.id && type(request.value) == 'int')
			return sprintf('%d:d:%d', request.id, request.value);
		if (request.vendor_id && request.vendor_attributes) {
			let tlv = sprintf('26:x:%04x', request.vendor_id);
			for (let vsa in request.vendor_attributes)
				tlv += sprintf('%02x%02x', vsa.type, length(vsa.value)) + vsa.id;
			return tlv;
		}
		return '';
	}

	function calculate_ifname(name) {
		if ('captive' in ssid.services)
			return 'wlanc' + captive.get(name);
		return '';
	}

	function match_band(phy) {
		for (let band in ssid.wifi_bands) {
			if (band in phy.band)
				return band;
		}
		return null;
	}

	// Configuration generation functions
	function generate_halow_mesh_config(phy, crypto, mode) {
		let band = match_band(phy);
		if (!(is_halow_band(band) && is_mesh_mode(mode)))
			return '';

		let output = [];

		uci_comment(output, '# generated by interface/ssid.uc');
		uci_comment(output, '### generate HaLow mesh specific configuration');
		uci_named_section(output, 'wireless.halowmesh', 'wifi-iface');
		uci_set_string(output, 'wireless.halowmesh.device', phy.section);
		uci_set_string(output, 'wireless.halowmesh.ifname', 'halow_mesh');
		uci_set_string(output, 'wireless.halowmesh.disabled', '0');
		uci_set_string(output, 'wireless.halowmesh.beacon_int', '1000');
		uci_set_string(output, 'wireless.halowmesh.wds', '0');
		uci_set_string(output, 'wireless.halowmesh.network', network);
		uci_set_string(output, 'wireless.halowmesh.mode', bss_mode);
		uci_set_string(output, 'wireless.halowmesh.network_behavior', substr(network, 0, 2) == "up" ? "bridge" : "lan");
		uci_set_string(output, 'wireless.halowmesh.mesh_id', ssid.name);
		uci_set_string(output, 'wireless.halowmesh.encryption', crypto.proto);
		uci_set_string(output, 'wireless.halowmesh.key', crypto.key);

		return uci_output(output);
	}

	function generate_base_wireless_config(section, phy, ifname, mode) {
		let output = [];

		if (!generate_halow_mesh_config(phy, {}, mode)) {
			uci_comment(output, '# generated by interface/ssid.uc');
		}
		uci_comment(output, '### generate base wireless interface configuration');
		uci_named_section(output, `wireless.${section}`, 'wifi-iface');
		uci_set_string(output, `wireless.${section}.ucentral_path`, location);
		uci_set_string(output, `wireless.${section}.uci_section`, section);
		uci_set_string(output, `wireless.${section}.device`, phy.section);

		if (has_captive_service())
			uci_set_string(output, `wireless.${section}.ifname`, ifname);

		return uci_output(output);
	}

	function generate_captive_integration(section, basename, ifname) {
		if (!has_captive_service())
			return '';

		let output = [];

		uci_comment(output, '### generate captive portal integration');
		uci_list_string(output, `uspot.${basename}.ifname`, ifname);
		uci_list_string(output, 'bridger.@defaults[0].blacklist', ifname);

		return uci_output(output);
	}

	function generate_owe_transition_config(section) {
		if (ssid?.encryption?.proto != 'owe-transition')
			return '';

		let output = [];

		uci_comment(output, '### generate OWE transition configuration');
		// Modify ssid for OWE transition
		ssid.hidden_ssid = 1;
		ssid.name += '-OWE';
		uci_set_string(output, `wireless.${section}.ifname`, section);
		uci_set_string(output, `wireless.${section}.owe_transition_ifname`, 'o' + section);

		return uci_output(output);
	}

	function generate_owe_config(section, ssidname, owe) {
		if (!owe)
			return '';

		let output = [];

		uci_comment(output, '### generate OWE configuration');
		uci_set_string(output, `wireless.${section}.ifname`, section);
		uci_set_string(output, `wireless.${section}.owe_transition_ifname`, ssidname);
		uci_set_string(output, `wireless.${section}.owe_transition_ssid`, ssid.name + '-OWE');

		return uci_output(output);
	}

	function generate_mesh_config(section, mode) {
		if (!is_mesh_mode(mode))
			return '';

		let output = [];

		uci_comment(output, '### generate mesh configuration');
		uci_set_string(output, `wireless.${section}.mode`, bss_mode);
		uci_set_string(output, `wireless.${section}.mesh_id`, ssid.name);
		uci_set_number(output, `wireless.${section}.mesh_fwding`, 0);

		if (tunnel_proto == 'mesh')
			uci_set_string(output, `wireless.${section}.network`, 'batman_mesh');

		uci_set_number(output, `wireless.${section}.mcast_rate`, 24000);

		return uci_output(output);
	}

	function generate_ap_sta_config(section, mode) {
		if (!is_ap_sta_mode(mode))
			return '';

		let output = [];

		uci_comment(output, '### generate AP/STA configuration');
		uci_set_string(output, `wireless.${section}.network`, network);
		uci_set_string(output, `wireless.${section}.ssid`, ssid.name);
		uci_set_string(output, `wireless.${section}.mode`, bss_mode);
		uci_set_string(output, `wireless.${section}.bssid`, ssid.bssid);
		uci_set_boolean(output, `wireless.${section}.wds`, match_wds());
		uci_set_boolean(output, `wireless.${section}.wpa_disable_eapol_key_retries`, ssid.wpa_disable_eapol_key_retries);
		uci_set_string(output, `wireless.${section}.vendor_elements`, ssid.vendor_elements);
		uci_set_boolean(output, `wireless.${section}.disassoc_low_ack`, ssid.disassoc_low_ack);
		uci_set_boolean(output, `wireless.${section}.auth_cache`, ssid.multi_psk ? 0 : ssid.encryption?.key_caching);

		return uci_output(output);
	}

	function generate_band_specific_config(section, band) {
		let output = [];

		if (is_6g_band(band)) {
			uci_comment(output, '### generate 6G band configuration');
			uci_set_number(output, `wireless.${section}.fils_discovery_max_interval`, ssid.fils_discovery_interval);
		}

		if (is_halow_band(band)) {
			uci_comment(output, '### generate HaLow band configuration');
			uci_set_number(output, `wireless.${section}.wpa_strict_rekey`, 0);
			uci_set_number(output, `wireless.${section}.wpa_group_rekey`, 0);
			uci_set_number(output, `wireless.${section}.eap_reauth_period`, 0);
		}

		return uci_output(output);
	}

	function generate_crypto_base_config(section, band, crypto) {
		let output = [];

		uci_comment(output, '### generate crypto settings');
		uci_set_number(output, `wireless.${section}.ieee80211w`, match_ieee80211w(band));
		uci_set_string(output, `wireless.${section}.sae_pwe`, match_sae_pwe(band));
		uci_set_string(output, `wireless.${section}.encryption`, crypto.proto);
		uci_set_string(output, `wireless.${section}.key`, crypto.key);

		return uci_output(output);
	}

	function generate_eap_local_config(section, crypto) {
		if (!crypto.eap_local)
			return '';

		let output = [];

		uci_comment(output, '### generate EAP local configuration');
		uci_set_number(output, `wireless.${section}.eap_server`, 1);
		uci_set_string(output, `wireless.${section}.ca_cert`, certificates.ca_certificate);
		uci_set_string(output, `wireless.${section}.server_cert`, certificates.certificate);
		uci_set_string(output, `wireless.${section}.private_key`, certificates.private_key);
		uci_set_string(output, `wireless.${section}.private_key_passwd`, certificates.private_key_password);
		uci_set_string(output, `wireless.${section}.server_id`, crypto.eap_local.server_identity);
		uci_set_string(output, `wireless.${section}.eap_user_file`, crypto.eap_user);

		return uci_output(output);
	}

	function generate_radius_auth_config(section, crypto, n, count, use_proxy) {
		if (!crypto.auth)
			return '';

		let output = [];

		uci_comment(output, '### generate RADIUS authentication configuration');

		if (use_proxy)
			uci_set_number(output, `wireless.${section}.radius_gw_proxy`, 1);

		uci_set_string(output, `wireless.${section}.auth_server`, use_proxy ? '127.0.0.1' : crypto.auth.host);
		uci_set_number(output, `wireless.${section}.auth_port`, use_proxy ? 1812 : crypto.auth.port);
		uci_set_string(output, `wireless.${section}.auth_secret`, crypto.auth.secret);

		for (let request in crypto.auth.request_attribute)
			uci_list_string(output, `wireless.${section}.radius_auth_req_attr`, radius_request_attribute(request));

		if (use_proxy)
			uci_list_string(output, `wireless.${section}.radius_auth_req_attr`, radius_proxy_tlv(crypto.auth.host, crypto.auth.port, name + '_' + n + '_' + count));
		else
			uci_list_string(output, `wireless.${section}.radius_auth_req_attr`, radius_vendor_tlv(crypto.auth.host, crypto.auth.port));

		if (crypto.auth.secondary) {
			uci_set_string(output, `wireless.${section}.auth_server_secondary`, crypto.auth.secondary.host);
			uci_set_number(output, `wireless.${section}.auth_port_secondary`, crypto.auth.secondary.port);
			uci_set_string(output, `wireless.${section}.auth_secret_secondary`, crypto.auth.secondary.secret);
		}

		return uci_output(output);
	}

	function generate_radius_acct_config(section, crypto, n, count, use_proxy) {
		if (!crypto.acct)
			return '';

		let output = [];

		uci_comment(output, '### generate RADIUS accounting configuration');
		uci_set_string(output, `wireless.${section}.acct_server`, use_proxy ? '127.0.0.1' : crypto.acct.host);
		uci_set_number(output, `wireless.${section}.acct_port`, use_proxy ? 1813 : crypto.acct.port);
		uci_set_string(output, `wireless.${section}.acct_secret`, crypto.acct.secret);
		uci_set_number(output, `wireless.${section}.acct_interval`, crypto.acct.interval);

		for (let request in crypto.acct.request_attribute)
			uci_list_string(output, `wireless.${section}.radius_acct_req_attr`, radius_request_attribute(request));

		if (use_proxy)
			uci_list_string(output, `wireless.${section}.radius_acct_req_attr`, radius_proxy_tlv(crypto.acct.host, crypto.acct.port, name + '_' + n + '_' + count));
		else
			uci_list_string(output, `wireless.${section}.radius_acct_req_attr`, radius_vendor_tlv(crypto.acct.host, crypto.acct.port));

		if (crypto.acct.secondary) {
			uci_set_string(output, `wireless.${section}.acct_server_secondary`, crypto.acct.secondary.host);
			uci_set_number(output, `wireless.${section}.acct_port_secondary`, crypto.acct.secondary.port);
			uci_set_string(output, `wireless.${section}.acct_secret_secondary`, crypto.acct.secondary.secret);
		}

		return uci_output(output);
	}

	function generate_radius_health_config(section, crypto) {
		if (!crypto.health)
			return '';

		let output = [];

		uci_comment(output, '### generate RADIUS health configuration');
		uci_set_string(output, `wireless.${section}.health_username`, crypto.health.username);
		uci_set_string(output, `wireless.${section}.health_password`, crypto.health.password);

		return uci_output(output);
	}

	function generate_dynamic_auth_config(section, crypto) {
		if (!crypto.dyn_auth)
			return '';

		let output = [];

		uci_comment(output, '### generate dynamic authorization configuration');
		uci_set_string(output, `wireless.${section}.dae_client`, crypto.dyn_auth.host);
		uci_set_number(output, `wireless.${section}.dae_port`, crypto.dyn_auth.port);
		uci_set_string(output, `wireless.${section}.dae_secret`, crypto.dyn_auth.secret);

		uci_named_section(output, 'firewall.dyn_auth', 'rule');
		uci_set_string(output, 'firewall.dyn_auth.name', 'Allow-CoA');
		uci_set_string(output, 'firewall.dyn_auth.src', ethernet.find_interface("upstream", 0));
		uci_set_string(output, 'firewall.dyn_auth.dest_port', crypto.dyn_auth.port);
		uci_set_string(output, 'firewall.dyn_auth.proto', 'udp');
		uci_set_string(output, 'firewall.dyn_auth.target', 'ACCEPT');

		return uci_output(output);
	}

	function generate_radius_general_config(section, crypto) {
		if (!crypto.radius)
			return '';

		let output = [];

		uci_comment(output, '### generate RADIUS general configuration');
		uci_set_boolean(output, `wireless.${section}.request_cui`, crypto.radius.chargeable_user_id);
		uci_set_string(output, `wireless.${section}.nasid`, crypto.radius.nas_identifier);
		uci_set_number(output, `wireless.${section}.dynamic_vlan`, 1);

		if (crypto.radius?.authentication?.mac_filter)
			uci_set_string(output, `wireless.${section}.macfilter`, 'radius');

		return uci_output(output);
	}

	function generate_client_tls_config(section, crypto) {
		if (!crypto.client_tls)
			return '';

		let output = [];

		uci_comment(output, '### generate client TLS configuration');
		uci_set_string(output, `wireless.${section}.eap_type`, 'tls');
		uci_set_string(output, `wireless.${section}.ca_cert`, certificates.ca_certificate);
		uci_set_string(output, `wireless.${section}.client_cert`, certificates.certificate);
		uci_set_string(output, `wireless.${section}.priv_key`, certificates.private_key);
		uci_set_string(output, `wireless.${section}.priv_key_pwd`, certificates.private_key_password);
		uci_set_string(output, `wireless.${section}.identity`, 'uCentral');

		return uci_output(output);
	}

	function generate_vlan_awareness_config(section, mode) {
		let output = [];

		if (interface.vlan_awareness?.first) {
			let vlan = interface.vlan_awareness.first;
			if (interface.vlan_awareness.last)
				vlan += '-' + interface.vlan_awareness.last;

			uci_comment(output, '### generate interface VLAN awareness');
			uci_set_string(output, `wireless.${section}.network_vlan`, vlan);
		} else if (ssid.vlan_awareness?.first && mode == 'sta') {
			let vlan = ssid.vlan_awareness.first;
			if (ssid.vlan_awareness.last)
				vlan += '-' + ssid.vlan_awareness.last;

			uci_comment(output, '### generate SSID VLAN awareness');
			uci_set_string(output, `wireless.${section}.network_vlan`, vlan);
		}

		return uci_output(output);
	}

	function generate_ap_specific_config(section, mode) {
		if (mode != 'ap')
			return '';

		let output = [];

		uci_comment(output, '### generate AP specific settings');
		uci_set_boolean(output, `wireless.${section}.proxy_arp`, length(network) ? ssid.proxy_arp : false);
		uci_set_boolean(output, `wireless.${section}.hidden`, ssid.hidden_ssid);
		uci_set_number(output, `wireless.${section}.time_advertisement`, ssid.broadcast_time ? 2 : 0);
		uci_set_boolean(output, `wireless.${section}.isolate`, ssid.isolate_clients || interface.isolate_hosts);
		uci_set_boolean(output, `wireless.${section}.bridge_isolate`, interface.isolate_hosts);
		uci_set_string(output, `wireless.${section}.max_inactivity`, ssid.max_inactivity);
		uci_set_boolean(output, `wireless.${section}.uapsd`, ssid.power_save);
		uci_set_number(output, `wireless.${section}.rts_threshold`, ssid.rts_threshold);
		uci_set_boolean(output, `wireless.${section}.multicast_to_unicast`, ssid.unicast_conversion);
		uci_set_number(output, `wireless.${section}.maxassoc`, ssid.maximum_clients);
		uci_set_number(output, `wireless.${section}.dtim_period`, ssid.dtim_period);
		uci_set_boolean(output, `wireless.${section}.strict_forwarding`, ssid.strict_forwarding);

		if (interface?.vlan.id)
			uci_set_number(output, `wireless.${section}.vlan_id`, interface.vlan.id);

		if (ssid.rate_limit)
			uci_set_number(output, `wireless.${section}.ratelimit`, 1);

		return uci_output(output);
	}

	function generate_access_control_config(section) {
		if (!ssid.access_control_list?.mode)
			return '';

		let output = [];

		uci_comment(output, '### generate access control configuration');
		uci_set_string(output, `wireless.${section}.macfilter`, ssid.access_control_list.mode);

		for (let mac in ssid.access_control_list.mac_address)
			uci_list_string(output, `wireless.${section}.maclist`, mac);

		return uci_output(output);
	}

	function generate_rrm_config(section) {
		if (!ssid.rrm)
			return '';

		let output = [];

		uci_comment(output, '### generate RRM configuration');
		uci_set_boolean(output, `wireless.${section}.ieee80211k`, ssid.rrm.neighbor_reporting);
		uci_set_boolean(output, `wireless.${section}.rnr`, ssid.rrm.reduced_neighbor_reporting);
		uci_set_boolean(output, `wireless.${section}.ftm_responder`, ssid.rrm.ftm_responder);
		uci_set_boolean(output, `wireless.${section}.stationary_ap`, ssid.rrm.stationary_ap);
		uci_set_boolean(output, `wireless.${section}.lci`, ssid.rrm.lci);
		uci_set_string(output, `wireless.${section}.civic`, ssid.rrm.civic);

		return uci_output(output);
	}

	function generate_roaming_config(section) {
		if (!has_roaming())
			return '';

		let output = [];

		uci_comment(output, '### generate roaming configuration');
		uci_set_number(output, `wireless.${section}.ieee80211r`, 1);
		uci_set_boolean(output, `wireless.${section}.ft_over_ds`, ssid.roaming.message_exchange == "ds");
		uci_set_boolean(output, `wireless.${section}.ft_psk_generate_local`, ssid.roaming.generate_psk);
		uci_set_string(output, `wireless.${section}.mobility_domain`, ssid.roaming.domain_identifier);
		uci_set_string(output, `wireless.${section}.r0kh`, ssid.roaming.pmk_r0_key_holder);
		uci_set_string(output, `wireless.${section}.r1kh`, ssid.roaming.pmk_r1_key_holder);
		uci_set_string(output, `wireless.${section}.ft_key`, ssid.roaming.key_aes_256);

		return uci_output(output);
	}

	function generate_multi_psk_base_config(section) {
		let output = [];

		uci_comment(output, '### generate multi-PSK base configuration');
		uci_set_boolean(output, `wireless.${section}.multi_psk`, ssid.multi_psk);

		return uci_output(output);
	}

	function generate_quality_thresholds_config(section) {
		if (!ssid.quality_thresholds)
			return '';

		let output = [];

		uci_comment(output, '### generate quality thresholds configuration');
		uci_set_number(output, `wireless.${section}.rssi_reject_assoc_rssi`, ssid.quality_thresholds.association_request_rssi);
		uci_set_number(output, `wireless.${section}.rssi_ignore_probe_request`, ssid.quality_thresholds.probe_request_rssi);

		if (ssid.quality_thresholds.probe_request_rssi)
			uci_set_number(output, `wireless.${section}.dynamic_probe_resp`, 1);

		return uci_output(output);
	}

	function generate_hostapd_raw_config(section) {
		if (!ssid.hostapd_bss_raw || !length(ssid.hostapd_bss_raw))
			return '';

		let output = [];

		uci_comment(output, '### generate hostapd raw options');

		for (let raw in ssid.hostapd_bss_raw)
			uci_list_string(output, `wireless.${section}.hostapd_bss_options`, raw);

		return uci_output(output);
	}

	function generate_passpoint_config(section) {
		if (!has_pass_point())
			return '';

		let output = [];

		uci_comment(output, '### generate Passpoint/Hotspot 2.0 configuration');
		uci_set_number(output, `wireless.${section}.iw_enabled`, 1);
		uci_set_number(output, `wireless.${section}.hs20`, 1);

		for (let name in ssid.pass_point.venue_name)
			uci_list_string(output, `wireless.${section}.iw_venue_name`, name);

		uci_set_string(output, `wireless.${section}.iw_venue_group`, ssid.pass_point.venue_group);
		uci_set_string(output, `wireless.${section}.iw_venue_type`, ssid.pass_point.venue_type);

		for (let n, url in ssid.pass_point.venue_url)
			uci_list_string(output, `wireless.${section}.iw_venue_url`, (n + 1) + ":" + url);

		uci_set_string(output, `wireless.${section}.iw_network_auth_type`, match_hs20_auth_type(ssid.pass_point.auth_type));
		uci_set_string(output, `wireless.${section}.iw_domain_name`, join(",", ssid.pass_point.domain_name));

		for (let realm in ssid.pass_point.nai_realm)
			uci_list_string(output, `wireless.${section}.iw_nai_realm`, realm);

		uci_set_boolean(output, `wireless.${section}.osen`, ssid.pass_point.osen);
		uci_set_string(output, `wireless.${section}.anqp_domain_id`, ssid.pass_point.anqp_domain);

		for (let cell_net in ssid.pass_point.anqp_3gpp_cell_net)
			uci_list_string(output, `wireless.${section}.iw_anqp_3gpp_cell_net`, cell_net);

		for (let name in ssid.pass_point.friendly_name)
			uci_list_string(output, `wireless.${section}.hs20_oper_friendly_name`, name);

		uci_set_string(output, `wireless.${section}.iw_access_network_type`, ssid.pass_point.access_network_type);
		uci_set_boolean(output, `wireless.${section}.iw_internet`, ssid.pass_point.internet);
		uci_set_boolean(output, `wireless.${section}.iw_asra`, ssid.pass_point.asra);
		uci_set_boolean(output, `wireless.${section}.iw_esr`, ssid.pass_point.esr);
		uci_set_boolean(output, `wireless.${section}.iw_uesa`, ssid.pass_point.uesa);
		uci_set_string(output, `wireless.${section}.iw_hessid`, ssid.pass_point.hessid);

		for (let name in ssid.pass_point.roaming_consortium)
			uci_list_string(output, `wireless.${section}.iw_roaming_consortium`, name);

		uci_set_boolean(output, `wireless.${section}.disable_dgaf`, ssid.pass_point.disable_dgaf);
		uci_set_string(output, `wireless.${section}.hs20_release`, '3');
		uci_set_string(output, `wireless.${section}.iw_ipaddr_type_availability`, sprintf("%02x", ssid.pass_point.ipaddr_type_availability));

		for (let name in ssid.pass_point.connection_capability)
			uci_list_string(output, `wireless.${section}.hs20_conn_capab`, name);

		uci_set_string(output, `wireless.${section}.hs20_wan_metrics`, get_hs20_wan_metrics());

		return uci_output(output);
	}

	function generate_passpoint_icons_config() {
		if (!has_pass_point() || !ssid.pass_point.icons)
			return '';

		let output = [];

		uci_comment(output, '### generate Passpoint icons configuration');

		for (let id, icon in ssid.pass_point.icons) {
			uci_section(output, 'wireless hs20-icon');
			uci_set_string(output, 'wireless.@hs20-icon[-1].width', icon.width);
			uci_set_string(output, 'wireless.@hs20-icon[-1].height', icon.height);
			uci_set_string(output, 'wireless.@hs20-icon[-1].type', icon.type);
			uci_set_string(output, 'wireless.@hs20-icon[-1].lang', icon.language);
			uci_set_string(output, 'wireless.@hs20-icon[-1].path', files.add_anonymous(location, 'hs20_icon_' + id, b64dec(icon.icon)));
		}

		return uci_output(output);
	}

	function generate_multi_psk_reassoc_config(section) {
		if (!length(ssid.multi_psk))
			return '';

		let output = [];

		uci_comment(output, '### generate multi-PSK reassociation configuration');
		uci_set_number(output, `wireless.${section}.reassociation_deadline`, 3000);

		return uci_output(output);
	}

	function generate_wifi_vlan_config(section) {
		let output = [];

		uci_comment(output, '### generate wifi VLAN configuration');
		uci_section(output, 'wireless wifi-vlan');
		uci_set_string(output, 'wireless.@wifi-vlan[-1].iface', section);
		uci_set_string(output, 'wireless.@wifi-vlan[-1].name', 'v#');
		uci_set_string(output, 'wireless.@wifi-vlan[-1].vid', '*');

		return uci_output(output);
	}

	function generate_rate_limit_config() {
		if (!has_rate_limit())
			return '';

		let output = [];

		uci_comment(output, '### generate rate limiting configuration');
		uci_section(output, 'ratelimit rate');
		uci_set_string(output, 'ratelimit.@rate[-1].ssid', ssid.name);
		uci_set_number(output, 'ratelimit.@rate[-1].ingress', ssid.rate_limit.ingress_rate);
		uci_set_number(output, 'ratelimit.@rate[-1].egress', ssid.rate_limit.egress_rate);

		return uci_output(output);
	}

	function generate_multi_psk_stations_config(section) {
		if (!length(ssid.multi_psk))
			return '';

		let output = [];

		uci_comment(output, '### generate multi-PSK stations configuration');

		for (let i = length(ssid.multi_psk); i > 0; i--) {
			let psk = ssid.multi_psk[i - 1];
			if (!psk.key)
				continue;

			uci_section(output, 'wireless wifi-station');
			uci_set_string(output, 'wireless.@wifi-station[-1].iface', section);
			uci_set_string(output, 'wireless.@wifi-station[-1].mac', psk.mac);
			uci_set_string(output, 'wireless.@wifi-station[-1].key', psk.key);
			uci_set_string(output, 'wireless.@wifi-station[-1].vid', psk.vlan_id);
		}

		if (length(ssid.multi_psk)) {
			uci_section(output, 'wireless wifi-station');
			uci_set_string(output, 'wireless.@wifi-station[-1].iface', section);
			uci_set_string(output, 'wireless.@wifi-station[-1].key', ssid.encryption.key);
		}

		return uci_output(output);
	}

	// Main logic and variable initialization
	let bss_mode = normalize_bss_mode();
	let radius_gw_proxy = has_radius_gw_proxy();

	// Normalize configurations
	normalize_roaming_config();
	normalize_radius_dynamic_auth();
	normalize_vendor_elements();

	// Service integrations
	if (has_captive_service() && !ssid.captive)
		ssid.captive = state?.services?.captive || {};

	if (ssid.captive) {
		include("captive.uc", {
			section: name + '_' + count,
			config: ssid.captive
		});
	}

	if (ssid.strict_forwarding)
		services.set_enabled("bridger", 'early');
%}

# Wireless configuration
{% for (let n, phy in phys): %}
{%   let basename = name + '_' + count; %}
{%   let ssidname = basename + '_' + n + '_' + count; %}
{%   let section = (owe ? 'o' : '' ) + ssidname; %}
{%   let id = wiphy.allocate_ssid_section_id(phy) %}
{%   let band = match_band(phy); %}
{%   if (!band) continue; %}
{%   let crypto = match_crypto(band); %}
{%   let ifname = calculate_ifname(basename) %}
{%   if (!crypto) continue; %}

{{ generate_halow_mesh_config(phy, crypto, bss_mode) }}
{%   if (!(band == "HaLow" && bss_mode == 'mesh')): %}
{{ generate_base_wireless_config(section, phy, ifname, bss_mode) }}
{{ generate_captive_integration(section, basename, ifname) }}
{{ generate_owe_transition_config(section) }}
{{ generate_owe_config(section, ssidname, owe) }}
{{ generate_mesh_config(section, bss_mode) }}

{{ generate_ap_sta_config(section, bss_mode) }}
{{ generate_band_specific_config(section, band) }}
{{ generate_crypto_base_config(section, band, crypto) }}
{% if (crypto.eap_local): %}
{{ generate_eap_local_config(section, crypto) }}
{%     files.add_named(crypto.eap_user, render("../eap_users.uc", { users: crypto.eap_local.users })) %}
{% endif %}
{{ generate_radius_auth_config(section, crypto, n, count, radius_gw_proxy) }}
{{ generate_radius_acct_config(section, crypto, n, count, radius_gw_proxy) }}
{{ generate_radius_health_config(section, crypto) }}
{{ generate_dynamic_auth_config(section, crypto) }}
{{ generate_radius_general_config(section, crypto) }}
{{ generate_client_tls_config(section, crypto) }}
{{ generate_vlan_awareness_config(section, bss_mode) }}
{{ generate_ap_specific_config(section, bss_mode) }}
{{ generate_access_control_config(section) }}
{{ generate_rrm_config(section) }}
{{ generate_roaming_config(section) }}
{{ generate_multi_psk_base_config(section) }}
{{ generate_quality_thresholds_config(section) }}
{{ generate_hostapd_raw_config(section) }}
{{ generate_passpoint_config(section) }}

{% include("wmm.uc", { section }); %}

{{ generate_multi_psk_reassoc_config(section) }}
{{ generate_passpoint_icons_config() }}
{{ generate_wifi_vlan_config(section) }}
{{ generate_rate_limit_config() }}
{{ generate_multi_psk_stations_config(section) }}
{%   else %}

# STA specific settings
{%   endif %}
{% endfor %}
