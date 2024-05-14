{%
	let purpose = {
		"onboarding-ap": {
			"name": "OpenWifi-onboarding",
			"isolate_clients": true,
			"hidden": true,
			"wifi_bands": [
				"2G"
			],
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
			"wifi_bands": [
				"2G"
			],
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

	if (purpose[ssid.purpose])
		ssid = purpose[ssid.purpose];

	let phys = [];

	for (let band in ssid.wifi_bands)
		for (let phy in wiphy.lookup_by_band(band))
			if (phy.section)
				push(phys, phy);

	if (!length(phys)) {
		warn("Can't find any suitable radio phy for SSID '%s' settings", ssid.name);

		return;
	}

	if (type(ssid.roaming) == 'bool')
		ssid.roaming = {
			message_exchange: 'air',
			generate_psk: true,
		};

	if (ssid.roaming && ssid.encryption.proto in [ "wpa", "psk", "none" ]) {
		delete ssid.roaming;
		warn("Roaming requires wpa2 or later");
	}

	let certificates = ssid.certificates || {};
	if (certificates.use_local_certificates) {
		cursor.load("system");
		let certs = cursor.get_all("system", "@certificates[-1]");
		certificates.ca_certificate = certs.ca;
		certificates.certificate = certs.cert;
		certificates.private_key = certs.key;
	}

	if (ssid.radius?.dynamic_authorization && 'radius-gw-proxy' in ssid.services) {
		ssid.radius.dynamic_authorization.host = '127.0.0.1';
		ssid.radius.dynamic_authorization.port = 3799;
	}

	function validate_encryption_ap() {
		if (ssid.encryption.proto in [ "wpa", "wpa2", "wpa-mixed", "wpa3", "wpa3-mixed", "wpa3-192", "psk2-radius" ] &&
		    ssid.radius && ssid.radius.local &&
		    length(certificates))
			return {
				proto: ssid.encryption.proto,
				eap_local: ssid.radius.local,
				eap_user: "/tmp/ucentral/" + replace(location, "/", "_") + ".eap_user"
			};


		if (ssid.encryption.proto in [ "wpa", "wpa2", "wpa-mixed", "wpa3", "wpa3-mixed", "wpa3-192", "psk2-radius" ] &&
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
		if (ssid.encryption.proto in [ "wpa", "wpa2", "wpa-mixed", "wpa3", "wpa3-mixed", "wpa3-192" ] &&
		    length(certificates))
			return {
				proto: ssid.encryption.proto,
				client_tls: certificates
			};
		warn("Can't find any valid encryption settings");
		return false;
	}

	function validate_encryption(phy) {
		if ('6G' in phy.band && !(ssid?.encryption.proto in [ "wpa3", "wpa3-mixed", "wpa3-192", "sae", "sae-mixed", "owe" ])) {
			warn("Invalid encryption settings for 6G band");
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

		if (ssid.encryption.proto in [ "psk", "psk2", "psk-mixed", "sae", "sae-mixed" ] &&
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

	function match_ieee80211w(phy) {
		if ('6G' in phy.band)
			return 2;

		if (!ssid.encryption)
			return 0;

		if (ssid.encryption.proto in [ "sae-mixed", "wpa3-mixed" ])
			return 1;

		if (ssid.encryption.proto in [ "sae", "wpa3", "wpa3-192" ])
			return 2;

		return index([ "disabled", "optional", "required" ], ssid.encryption.ieee80211w);
	}

	function match_sae_pwe(phy) {
		if ('6G' in phy.band)
			return 1;
		return '';
	}

	function match_wds() {
		return index([ "wds-ap", "wds-sta", "wds-repeater" ], ssid.bss_mode) >= 0;
	}

	function match_hs20_auth_type(auth_type) {
		let types = {
			"terms-and-conditions": "00",
			"online-enrollment": "01",
			"http-redirection": "02",
			"dns-redirection": "03"
		};
		return (auth_type && auth_type.type) ? types[auth_type.type] : '';
	}

	function get_hs20_wan_metrics() {
		if (!ssid.pass_point.wan_metrics ||
		    !ssid.pass_point.wan_metrics.info ||
		    !ssid.pass_point.wan_metrics.downlink ||
		    ! ssid.pass_point.wan_metrics.uplink)
			return '';
		let map = {"up": 1, "down": 2, "testing": 3};
		let info = map[ssid.pass_point.wan_metrics.info] ? map[ssid.pass_point.wan_metrics.info] : 1;
		return sprintf("%02d:%d:%d:0:0:0", info, ssid.pass_point.wan_metrics.downlink, ssid.pass_point.wan_metrics.uplink);
	}

	let bss_mode = ssid.bss_mode;
	if (ssid.bss_mode == "wds-ap")
		bss_mode =  "ap";
	if (ssid.bss_mode == "wds-sta")
		bss_mode =  "sta";

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

	let radius_gw_proxy = ssid.services && (index(ssid.services, "radius-gw-proxy") >= 0);

	if ('captive' in ssid.services && !ssid.captive)
		ssid.captive = state?.services?.captive || {};

	if (ssid.captive)
		include("captive.uc", {
			section: name + '_' + count,
			config: ssid.captive
		});
	if (ssid.strict_forwarding)
		services.set_enabled("bridger", 'early');

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
%}

# Wireless configuration
{% for (let n, phy in phys): %}
{%   let basename = name + '_' + count; %}
{%   let ssidname = basename + '_' + n + '_' + count; %}
{%   let section = (owe ? 'o' : '' ) + ssidname; %}
{%   let id = wiphy.allocate_ssid_section_id(phy) %}
{%   let crypto = validate_encryption(phy); %}
{%   let ifname = calculate_ifname(basename) %}
{%   if (!crypto) continue; %}
set wireless.{{ section }}=wifi-iface
set wireless.{{ section }}.ucentral_path={{ s(location) }}
set wireless.{{ section }}.uci_section={{ s(section) }}
set wireless.{{ section }}.device={{ phy.section }}
{%   if ('captive' in ssid.services): %}
set wireless.{{ section }}.ifname={{ s(ifname) }}
add_list uspot.{{ basename}}.ifname={{ ifname }}
add_list bridger.@defaults[0].blacklist={{ ifname }}
{%   endif %}
{%   if (ssid?.encryption?.proto == 'owe-transition'): %}
{%      ssid.hidden_ssid = 1 %}
{%      ssid.name += '-OWE' %}
set wireless.{{ section }}.ifname={{ s(section) }}
set wireless.{{ section }}.owe_transition_ifname={{ s('o' + section) }}
{%   endif %}
{%   if (owe): %}
set wireless.{{ section }}.ifname={{ s(section) }}
set wireless.{{ section }}.owe_transition_ifname={{ s(ssidname) }}
set wireless.{{ section }}.owe_transition_ssid={{ s(ssid.name + '-OWE') }}
{%   endif %}
{%   if (bss_mode == 'mesh'): %}
set wireless.{{ section }}.mode={{ bss_mode }}
set wireless.{{ section }}.mesh_id={{ s(ssid.name) }}
set wireless.{{ section }}.mesh_fwding=0
set wireless.{{ section }}.network=batman_mesh
set wireless.{{ section }}.mcast_rate=24000
{%   endif %}

{%   if (index([ 'ap', 'sta' ], bss_mode) >= 0): %}
set wireless.{{ section }}.network={{ network }}
set wireless.{{ section }}.ssid={{ s(ssid.name) }}
set wireless.{{ section }}.mode={{ s(bss_mode) }}
set wireless.{{ section }}.bssid={{ ssid.bssid }}
set wireless.{{ section }}.wds='{{ b(match_wds()) }}'
set wireless.{{ section }}.wpa_disable_eapol_key_retries='{{ b(ssid.wpa_disable_eapol_key_retries) }}'
set wireless.{{ section }}.vendor_elements='{{ ssid.vendor_elements }}'
set wireless.{{ section }}.disassoc_low_ack='{{ b(ssid.disassoc_low_ack) }}'
set wireless.{{ section }}.auth_cache='{{ b(ssid.encryption?.key_caching) }}'
{%   endif %}

{% if ('6G' in phy.band): %}
set wireless.{{ section }}.fils_discovery_max_interval={{ ssid.fils_discovery_interval }}
{%   endif %}

# Crypto settings
set wireless.{{ section }}.ieee80211w={{ match_ieee80211w(phy) }}
set wireless.{{ section }}.sae_pwe={{ match_sae_pwe(phy) }}
set wireless.{{ section }}.encryption={{ crypto.proto }}
set wireless.{{ section }}.key={{ s(crypto.key) }}

{%   if (crypto.eap_local): %}
set wireless.{{ section }}.eap_server=1
set wireless.{{ section }}.ca_cert={{ s(certificates.ca_certificate) }}
set wireless.{{ section }}.server_cert={{ s(certificates.certificate) }}
set wireless.{{ section }}.private_key={{ s(certificates.private_key) }}
set wireless.{{ section }}.private_key_passwd={{ s(certificates.private_key_password) }}
set wireless.{{ section }}.server_id={{ s(crypto.eap_local.server_identity) }}
set wireless.{{ section }}.eap_user_file={{ s(crypto.eap_user) }}
{%     files.add_named(crypto.eap_user, render("../eap_users.uc", { users: crypto.eap_local.users })) %}
{%   endif %}

{%   if (crypto.auth): %}
{%     if (radius_gw_proxy): %}
set wireless.{{ section }}.radius_gw_proxy=1
{%     endif %}
set wireless.{{ section }}.auth_server={{ radius_gw_proxy ? '127.0.0.1' : crypto.auth.host }}
set wireless.{{ section }}.auth_port={{ radius_gw_proxy ? 1812 : crypto.auth.port }}
set wireless.{{ section }}.auth_secret={{ crypto.auth.secret }}
{%     for (let request in crypto.auth.request_attribute): %}
add_list wireless.{{ section }}.radius_auth_req_attr={{ s(radius_request_attribute(request)) }}
{%     endfor %}
{%     if (radius_gw_proxy): %}
add_list wireless.{{ section }}.radius_auth_req_attr={{ s(radius_proxy_tlv(crypto.auth.host, crypto.auth.port, name + '_' + n + '_' + count)) }}
{%     else %}
add_list wireless.{{ section }}.radius_auth_req_attr={{ s(radius_vendor_tlv(crypto.auth.host, crypto.auth.port)) }}
{%     endif %}
{%     if (crypto.auth.secondary): %}
set wireless.{{ section }}.auth_server_secondary={{ crypto.auth.secondary.host }}
set wireless.{{ section }}.auth_port_secondary={{ crypto.auth.secondary.port }}
set wireless.{{ section }}.auth_secret_secondary={{ crypto.auth.secondary.secret }}
{%     endif %}
{%   endif %}

{%   if (crypto.acct): %}
set wireless.{{ section }}.acct_server={{ radius_gw_proxy ? '127.0.0.1' : crypto.acct.host }}
set wireless.{{ section }}.acct_port={{ radius_gw_proxy ? 1813 : crypto.acct.port }}
set wireless.{{ section }}.acct_secret={{ crypto.acct.secret }}
set wireless.{{ section }}.acct_interval={{ crypto.acct.interval }}
{%     for (let request in crypto.acct.request_attribute): %}
add_list wireless.{{ section }}.radius_acct_req_attr={{ s(radius_request_attribute(request)) }}
{%     endfor %}
{%     if (radius_gw_proxy): %}
add_list wireless.{{ section }}.radius_acct_req_attr={{ s(radius_proxy_tlv(crypto.acct.host, crypto.acct.port, name + '_' + n + '_' + count)) }}
{%     else %}
add_list wireless.{{ section }}.radius_acct_req_attr={{ s(radius_vendor_tlv(crypto.acct.host, crypto.acct.port)) }}
{%     endif %}
{%     if (crypto.acct.secondary): %}
set wireless.{{ section }}.acct_server_secondary={{ crypto.acct.secondary.host }}
set wireless.{{ section }}.acct_port_secondary={{ crypto.acct.secondary.port }}
set wireless.{{ section }}.acct_secret_secondary={{ crypto.acct.secondary.secret }}
{%     endif %}
{%   endif %}

{%   if (crypto.health): %}
set wireless.{{ section }}.health_username={{ s(crypto.health.username) }}
set wireless.{{ section }}.health_password={{ s(crypto.health.password) }}
{%   endif %}

{%   if (crypto.dyn_auth): %}
set wireless.{{ section }}.dae_client={{ crypto.dyn_auth.host }}
set wireless.{{ section }}.dae_port={{ crypto.dyn_auth.port }}
set wireless.{{ section }}.dae_secret={{ crypto.dyn_auth.secret }}

set firewall.dyn_auth=rule
set firewall.dyn_auth.name='Allow-CoA'
set firewall.dyn_auth.src='{{ s(ethernet.find_interface("upstream", 0)) }}'
set firewall.dyn_auth.dest_port='{{ crypto.dyn_auth.port }}'
set firewall.dyn_auth.proto='udp'
set firewall.dyn_auth.target='ACCEPT'
{%   endif %}

{%   if (crypto.radius): %}
set wireless.{{ section }}.request_cui={{ b(crypto.radius.chargeable_user_id) }}
set wireless.{{ section }}.nasid={{ s(crypto.radius.nas_identifier) }}
set wireless.{{ section }}.dynamic_vlan=1
{%     if (crypto.radius?.authentication?.mac_filter): %}
set wireless.{{ section }}.macfilter=radius
{%     endif %}
{%   endif %}

{%   if (crypto.client_tls): %}
set wireless.{{ section }}.eap_type='tls'
set wireless.{{ section }}.ca_cert={{ s(certificates.ca_certificate) }}
set wireless.{{ section }}.client_cert={{ s(certificates.certificate)}}
set wireless.{{ section }}.priv_key={{ s(certificates.private_key) }}
set wireless.{{ section }}.priv_key_pwd={{ s(certificates.private_key_password) }}
set wireless.{{ section }}.identity='uCentral'
{%   endif %}

{% if (interface.vlan_awareness?.first): %}
{%   let vlan = interface.vlan_awareness.first;
     if (interface.vlan_awareness.last)
	     vlan += '-' + interface.vlan_awareness.last; %}
set wireless.{{ section }}.network_vlan={{ vlan }}
{% elif (ssid.vlan_awareness?.first && bss_mode == 'sta'):
     let vlan = ssid.vlan_awareness.first;
     if (ssid.vlan_awareness.last)
	     vlan += '-' + ssid.vlan_awareness.last; %}
set wireless.{{ section }}.network_vlan={{ vlan }}
{% endif %}

# AP specific setings
{%   if (bss_mode == 'ap'): %}
set wireless.{{ section }}.proxy_arp={{ b(length(network) ? ssid.proxy_arp : false) }}
set wireless.{{ section }}.hidden={{ b(ssid.hidden_ssid) }}
set wireless.{{ section }}.time_advertisement={{ ssid.broadcast_time ? 2 : 0 }}
set wireless.{{ section }}.isolate={{ b(ssid.isolate_clients || interface.isolate_hosts) }}
set wireless.{{ section }}.bridge_isolate={{ b(interface.isolate_hosts) }}
set wireless.{{ section }}.uapsd={{ b(ssid.power_save) }}
set wireless.{{ section }}.rts_threshold={{ ssid.rts_threshold }}
set wireless.{{ section }}.multicast_to_unicast={{ b(ssid.unicast_conversion) }}
set wireless.{{ section }}.maxassoc={{ ssid.maximum_clients }}
set wireless.{{ section }}.dtim_period={{ ssid.dtim_period }}
set wireless.{{ section }}.strict_forwarding={{ b(ssid.strict_forwarding) }}

{%     if (interface?.vlan.id): %}
set wireless.{{ section }}.vlan_id={{ interface.vlan.id }}
{%     endif %}


{%     if (ssid.rate_limit): %}
set wireless.{{ section }}.ratelimit=1
{%     endif %}

{%     if (ssid.access_control_list?.mode): %}
set wireless.{{ section }}.macfilter={{ s(ssid.access_control_list.mode) }}
{%       for (let mac in ssid.access_control_list.mac_address): %}
add_list wireless.{{ section }}.maclist={{ s(mac) }}
{%       endfor %}
{%     endif %}

{%     if (ssid.rrm): %}
set wireless.{{ section }}.ieee80211k={{ b(ssid.rrm.neighbor_reporting) }}
set wireless.{{ section }}.rnr={{ b(ssid.rrm.reduced_neighbor_reporting) }}
set wireless.{{ section }}.ftm_responder={{ b(ssid.rrm.ftm_responder) }}
set wireless.{{ section }}.stationary_ap={{ b(ssid.rrm.stationary_ap) }}
set wireless.{{ section }}.lci={{ b(ssid.rrm.lci) }}
set wireless.{{ section }}.civic={{ ssid.rrm.civic }}
{%     endif %}

{%     if (ssid.roaming): %}
set wireless.{{ section }}.ieee80211r=1
set wireless.{{ section }}.ft_over_ds={{ b(ssid.roaming.message_exchange == "ds") }}
set wireless.{{ section }}.ft_psk_generate_local={{ b(ssid.roaming.generate_psk) }}
set wireless.{{ section }}.mobility_domain={{ ssid.roaming.domain_identifier }}
set wireless.{{ section }}.r0kh={{ s(ssid.roaming.pmk_r0_key_holder) }}
set wireless.{{ section }}.r1kh={{ s(ssid.roaming.pmk_r1_key_holder) }}
{%     endif %}

{%     if (ssid.quality_thresholds): %}
set wireless.{{ phy.section }}.rssi_reject_assoc_rssi={{ ssid.quality_thresholds.association_request_rssi }}
set wireless.{{ phy.section }}.rssi_ignore_probe_request={{ ssid.quality_thresholds.probe_request_rssi }}
{%       if (ssid.quality_thresholds.probe_request_rssi): %}
set wireless.{{ section }}.hidden=1
set wireless.{{ section }}.dynamic_probe_resp=1
{%       endif %}
set usteer2.{{ section }}=ssid
set usteer2.{{ section }}.client_kick_rssi={{ ssid.quality_thresholds.client_kick_rssi }}
set usteer2.{{ section }}.client_kick_ban_time={{ ssid.quality_thresholds.client_kick_ban_time }}
{%     endif %}

{%  for (let raw in ssid.hostapd_bss_raw): %}
add_list wireless.{{ section }}.hostapd_bss_options={{ s(raw) }}
{%  endfor %}

{%     if (ssid.pass_point): %}
set wireless.{{ section }}.iw_enabled=1
set wireless.{{ section }}.hs20=1
{%       for (let name in ssid.pass_point.venue_name): %}
add_list wireless.{{ section }}.iw_venue_name={{ s(name) }}
{%       endfor %}
set wireless.{{ section }}.iw_venue_group='{{ ssid.pass_point.venue_group }}'
set wireless.{{ section }}.iw_venue_type='{{ ssid.pass_point.venue_type }}'
{%       for (let n, url in ssid.pass_point.venue_url): %}
add_list wireless.{{ section }}.iw_venue_url={{ s((n + 1) + ":" +url) }}
{%       endfor %}
set wireless.{{ section }}.iw_network_auth_type='{{ match_hs20_auth_type(ssid.pass_point.auth_type) }}'
set wireless.{{ section }}.iw_domain_name={{ s(join(",", ssid.pass_point.domain_name)) }}
{%       for (let realm in ssid.pass_point.nai_realm): %}
add_list wireless.{{ section }}.iw_nai_realm='{{ realm }}'
{%       endfor %}
set wireless.{{ section }}.osen={{ b(ssid.pass_point.osen) }}
set wireless.{{ section }}.anqp_domain_id='{{ ssid.pass_point.anqp_domain }}'
{%       for (let cell_net in ssid.pass_point.anqp_3gpp_cell_net): %}
add_list wireless.{{ section }}.iw_anqp_3gpp_cell_net='{{ s(cell_net) }}'
{%       endfor %}
{%       for (let name in ssid.pass_point.friendly_name): %}
add_list wireless.{{ section }}.hs20_oper_friendly_name={{ s(name) }}
{%       endfor %}
set wireless.{{ section }}.iw_access_network_type='{{ ssid.pass_point.access_network_type }}'
set wireless.{{ section }}.iw_internet={{ b(ssid.pass_point.internet) }}
set wireless.{{ section }}.iw_asra={{ b(ssid.pass_point.asra) }}
set wireless.{{ section }}.iw_esr={{ b(ssid.pass_point.esr) }}
set wireless.{{ section }}.iw_uesa={{ b(ssid.pass_point.uesa) }}
set wireless.{{ section }}.iw_hessid={{ s(ssid.pass_point.hessid) }}
{%       for (let name in ssid.pass_point.roaming_consortium): %}
add_list wireless.{{ section }}.iw_roaming_consortium={{ s(name) }}
{%       endfor %}
set wireless.{{ section }}.disable_dgaf={{ b(ssid.pass_point.disable_dgaf) }}
set wireless.{{ section }}.hs20_release='3'
set wireless.{{ section }}.iw_ipaddr_type_availability={{ s(sprintf("%02x", ssid.pass_point.ipaddr_type_availability)) }}
{%       for (let name in ssid.pass_point.connection_capability): %}
add_list wireless.{{ section }}.hs20_conn_capab={{ s(name) }}
{%       endfor %}
set wireless.{{ section }}.hs20_wan_metrics={{ s(get_hs20_wan_metrics()) }}
{%     endif %}

{% include("wmm.uc", { section }); %}

{% if (length(ssid.multi_psk)): %}
set wireless.{{ section }}.reassociation_deadline=3000
{% endif %}


{%     if (ssid.pass_point): %}
{%       for (let id, icon in ssid.pass_point.icons): %}
add wireless hs20-icon
set wireless.@hs20-icon[-1].width={{ s(icon.width) }}
set wireless.@hs20-icon[-1].height={{ s(icon.height) }}
set wireless.@hs20-icon[-1].type={{ s(icon.type) }}
set wireless.@hs20-icon[-1].lang={{ s(icon.language) }}
set wireless.@hs20-icon[-1].path={{ s(files.add_anonymous(location, 'hs20_icon_' + id, b64dec(icon.icon))) }}
{%       endfor %}



{%     endif %}

add wireless wifi-vlan
set wireless.@wifi-vlan[-1].iface={{ section }}
set wireless.@wifi-vlan[-1].name='v#'
set wireless.@wifi-vlan[-1].vid='*'
{%     if (ssid.rate_limit && (ssid.rate_limit.ingress_rate || ssid.rate_limit.egress_rate)): %}

add ratelimit rate
set ratelimit.@rate[-1].ssid={{ s(ssid.name) }}
set ratelimit.@rate[-1].ingress={{ ssid.rate_limit.ingress_rate }}
set ratelimit.@rate[-1].egress={{ ssid.rate_limit.egress_rate }}
{%     endif %}
{%     for (let i = length(ssid.multi_psk); i > 0; i--): %}
{%       let psk = ssid.multi_psk[i - 1]; %}
{%       if (!psk.key) continue %}

add wireless wifi-station
set wireless.@wifi-station[-1].iface={{ s(section) }}
set wireless.@wifi-station[-1].mac={{ psk.mac }}
set wireless.@wifi-station[-1].key={{ psk.key }}
set wireless.@wifi-station[-1].vid={{ psk.vlan_id }}
{%     endfor %}
{%   else %}

# STA specific settings
{%   endif %}
{% endfor %}
