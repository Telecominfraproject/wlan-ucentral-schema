#!/usr/bin/ucode

REQUIRE_SEARCH_PATH = [ '/usr/share/ucentral/*.uc', ...REQUIRE_SEARCH_PATH ];

import * as libuci from 'uci';
import * as libubus from 'ubus';
let uci = libuci.cursor();
let ubus = libubus.connect();

import * as fs from 'fs';

// State object
let state = {
	unit: {},
	interfaces: {}
};

// Load all required UCI configs
function load_configs() {
	uci.load('health');
	uci.load('dhcp');
	uci.load('network');
	uci.load('wireless');
	return {
		health: uci.get_all('state', 'health'),
		dhcp: uci.get_all('dhcp'),
		wifi_config: uci.get_all('wireless'),
		wifi_state: require('wifi.iface'),
		rrmd_config: uci.get_all('rrmd')
	};
}

// Helper function: find SSID in wifi state
function find_ssid(ssid, wifi_state) {
	for (let name, iface in wifi_state)
		if (ssid == iface.ssid)
			return 0;
	return 1;
}

// Helper function: find SSID on a specific phy index
function find_ssid_on_phy(ssid, phy_idx, wifi_state) {
	for (let ifname, iface in wifi_state) {
		if (iface.ssid == ssid && iface.phy == phy_idx) {
			if (!iface.has_channel) {
				return -1;
			}
			return 0;
		}
	}
	return 1;
}

// Helper function: find SSID by interface name prefix
function find_ssid_by_prefix(ssid, prefix, wifi_state) {
	for (let ifname, iface in wifi_state) {
		if (iface.ssid == ssid && index(ifname, prefix) == 0) {
			if (!iface.has_channel) {
				return -1;
			}
			return 0;
		}
	}
	return 1;
}

// Helper function: find SSID on a specific phy filtered by band frequency range
function find_ssid_on_phy_band(ssid, phy_idx, band, wifi_state) {
	let band_ranges = {
		'2g': [2400, 2500],
		'5g': [5150, 5900],
		'6g': [5925, 7200],
	};
	let range = band_ranges[band];
	if (!range)
		return find_ssid_on_phy(ssid, phy_idx, wifi_state);

	for (let ifname, iface in wifi_state) {
		if (iface.ssid != ssid || iface.phy != phy_idx)
			continue;

		/*
		 * If interface has no channel (radio stuck), we can't verify band
		 * by frequency. Match it anyway — it's on the right phy and SSID,
		 * and no_channel is the more specific/useful error.
		 */
		if (!iface.has_channel)
			return -1;

		/* Check if any of the interface's frequencies fall within the expected band */
		let in_band = false;
		for (let f in iface.frequency) {
			if (f >= range[0] && f <= range[1]) {
				in_band = true;
				break;
			}
		}
		if (!in_band)
			continue;

		return 0;
	}
	return 1;
}

// Helper function: find SSID for a radio using match info
function find_ssid_for_radio(ssid, match_info, wifi_state) {
	if (match_info.match_mode == 'prefix')
		return find_ssid_by_prefix(ssid, match_info.ifname_prefix, wifi_state);
	else if (match_info.match_mode == 'phy_band')
		return find_ssid_on_phy_band(ssid, match_info.phy_idx, match_info.band, wifi_state);
	else
		return find_ssid_on_phy(ssid, match_info.phy_idx, wifi_state);
}

// Helper function: get radio match info from device config
function get_radio_match_info(section) {
	if (!section || !section.path)
		return null;

	let info = {};

	/* If device has ifname_prefix, use prefix-based matching (multi-radio single-phy chips) */
	if (section.ifname_prefix) {
		info.match_mode = 'prefix';
		info.ifname_prefix = section.ifname_prefix;
		return info;
	}

	/* Strip +N suffix used by multi-radio single-phy devices in UCI path */
	let base_path = section.path;
	let path_match = match(base_path, /^(.+)\+([0-9]+)$/);
	if (path_match)
		base_path = path_match[1];

	/* Resolve phy index from sysfs path */
	let phys = fs.glob(sprintf('/sys/devices/%s/ieee80211/phy*', base_path));
	if (!length(phys))
		phys = fs.glob(sprintf('/sys/devices/platform/%s/ieee80211/phy*', base_path));
	if (!length(phys))
		return null;

	sort(phys);

	/* If path had +N suffix, select the Nth phy under this device */
	let phy_offset = path_match ? int(path_match[2]) : 0;
	if (phy_offset >= length(phys))
		return null;

	let phy_name = fs.basename(phys[phy_offset]);
	let phy_idx;

	let idx_str = fs.readfile(sprintf('/sys/class/ieee80211/%s/index', phy_name));
	if (idx_str != null) {
		phy_idx = int(trim(idx_str));
	} else {
		let match_res = match(phy_name, /phy([0-9]+)/);
		if (match_res)
			phy_idx = int(match_res[1]);
		else
			return null;
	}

	/*
	 * If the device has a 'radio' option, multiple wifi-devices share the same
	 * phy (reconf-capable multi-band chips like EAP105). Use phy+band matching
	 * to distinguish radios by their configured band.
	 */
	if (section.radio != null && section.band) {
		info.match_mode = 'phy_band';
		info.phy_idx = phy_idx;
		info.band = section.band;
		return info;
	}

	info.match_mode = 'phy';
	info.phy_idx = phy_idx;
	return info;
}

// Health check: Radio status
function check_radio_health(wifi_config, wifi_state) {
	let radio_issues = {};

	for (let k, section in wifi_config) {
		if (section['.type'] == 'wifi-device') {
			let dev_name = section['.name'];
			let disabled = section.disabled;

			if (disabled == '1')
				continue;

			let match_info = get_radio_match_info(section);

			if (match_info == null)
				continue;

			let expected_ssids = [];
			for (let j, iface_section in wifi_config) {
				if (iface_section['.type'] == 'wifi-iface' && iface_section.device == dev_name) {
					push(expected_ssids, iface_section.ssid);
				}
			}

			let failed_ssids = {};
			for (let ssid in expected_ssids) {
				let result = find_ssid_for_radio(ssid, match_info, wifi_state);
				if (result != 0) {
					failed_ssids[ssid] = (result == -1) ? 'no_channel' : 'missing';
				}
			}

			if (length(failed_ssids)) {
				radio_issues[dev_name] = {
					failed_ssids: failed_ssids
				};
				if (match_info.match_mode == 'prefix')
					radio_issues[dev_name].prefix = match_info.ifname_prefix;
				else
					radio_issues[dev_name].phy = match_info.phy_idx;
			}
		}
	}

	return radio_issues;
}

// Helper function: RADIUS probe
function radius_probe(server, port, secret, user, pass) {
	let f = fs.open('/tmp/radius.conf', 'w');
	if (f) {
		f.write(sprintf('authserver %s:%d\n', server, port));
		f.write('servers /tmp/radius.servers\n');
		f.write('dictionary /etc/radcli/dictionary\n');
		f.write('radius_timeout 3\n');
		f.write('radius_retries 1\n');
		f.write('bindaddr *\n');
		f.close();
	}

	f = fs.open('/tmp/radius.servers', 'w');
	if (f) {
		f.write(sprintf('%s %s\n', server, secret));
		f.close();
	}
	return system(['/usr/sbin/radiusprobe', user, pass]);
}

// Health check: DHCP functionality
function check_dhcp_health(iface, config, dhcp) {
	let name = iface.interface;
	let device = iface.l3_device || iface.interface;
	let warnings = [];
	let health = {};

	let probe_dhcp = uci.get('network', iface.interface, 'dhcp_healthcheck') || false;

	if (dhcp[name]?.leasetime && +config.dhcp_local)
		probe_dhcp = true;

	if (iface?.data.leasetime && +config.dhcp_remote)
		probe_dhcp = true;

	if (probe_dhcp) {
		let rc = system(['/usr/sbin/dhcpdiscover', '-i', device, '-t', '5']);
		if (rc) {
			health.dhcp = false;
			push(warnings, 'DHCP did not offer any leases');
			ubus.call('event', 'event', {
				object: 'health',
				verb: 'dhcp',
				payload: { iface: name, error: 'DHCP did not offer any leases' }
			});
		}
	}

	return { health, warnings };
}

// Health check: DNS functionality
function check_dns_health(iface, config, dhcp) {
	let name = iface.interface;
	let warnings = [];
	let health = {};

	let probe_dns = false;

	if (length(iface['dns-server']) && +config.dns_remote)
		probe_dns = true;

	if (dhcp[name]?.dns_service && +config.dns_local)
		probe_dns = true;

	if (probe_dns) {
		let dns = iface['dns-server'];
		if (!length(dns) && iface['ipv4-address'] && iface['ipv4-address'][0])
			dns = [ iface['ipv4-address'][0]['address'] ];

		for (let ip in dns) {
			let rc = system(['/usr/sbin/dnsprobe', '-s', ip]);

			if (rc) {
				health.dns = false;
				push(warnings, `DNS ${ip} is not reachable`);
				ubus.call('event', 'event', {
					object: 'health',
					verb: 'dns',
					payload: { iface: name, error: `DNS ${ip} is not reachable.` }
				});
			}
		}
	}

	return { health, warnings };
}

// Health check: WiFi SSID and RADIUS functionality
function check_wifi_health(iface, wifi_config, wifi_state) {
	let name = iface.interface;
	let warnings = [];
	let health = {};
	let ssid = {};
	let radius = {};

	for (let k, wifi_iface in wifi_config) {
		if (wifi_iface['.type'] != 'wifi-iface' || wifi_iface.network != name)
			continue;

		// Check SSID availability
		if (find_ssid(wifi_iface.ssid, wifi_state))
			ssid[wifi_iface.ssid] = false;

		// Check RADIUS connectivity
		if (wifi_iface.auth_server &&
		    wifi_iface.auth_port &&
		    wifi_iface.auth_secret &&
		    wifi_iface.health_username &&
		    wifi_iface.health_password &&
		    !wifi_iface.radius_gw_proxy) {

			if (radius_probe(wifi_iface.auth_server,
			                wifi_iface.auth_port,
			                wifi_iface.auth_secret,
			                wifi_iface.health_username,
			                wifi_iface.health_password)) {

				radius[wifi_iface.ssid] = false;
				push(warnings, sprintf('Radius %s:%s is not reachable',
					wifi_iface.auth_server, wifi_iface.auth_port));
				ubus.call('event', 'event', {
					object: 'health',
					verb: 'radius',
					payload: {
						ssid: wifi_iface.ssid,
						error: `Radius ${wifi_iface.auth_server}:${wifi_iface.auth_port} is not reachable` 
					}
				});
			}
		}
	}

	if (length(ssid))
		health.ssids = ssid;

	if (length(radius))
		health.radius = radius;

	return { health, warnings };
}

// Health check: RRM channel utilization
function check_rrm_health(rrmd_config) {
	for (let l, policy in rrmd_config) {
		if (policy['.type'] != 'policy' || policy.name != 'chanutil')
			continue;

		let buffer_time = (policy.interval/1000) + 60;

		if (policy.threshold > 0 && (policy.algo == 1 || policy.algo == 2)) {
			if (fs.stat('/tmp/rrm_timestamp')) {
				let last_rrm_timestamp = int(fs.readfile('/tmp/rrm_timestamp'));
				let time_passed_since_rrm = time() - last_rrm_timestamp;

				// RRM with channel utilization is enabled but didn't run after the interval time: abnormal state
				if (time_passed_since_rrm > buffer_time) {
					state.rrm_chanutil = false;
				}
			}
		}
	}
}

// Health check: System memory
function check_memory_health() {
	try {
		let memory = ubus.call('system', 'info');
		memory = memory.memory;
		state.unit.memory = 100 - (memory.available * 100 / memory.total);
		if (state.unit.memory >= 90)
			ubus.call('event', 'event', {
				object: 'health',
				verb: 'memory',
				payload: {
					used: state.unit.memory,
					error: 'Memory is almost exhausted.'
				}
			});
	}
	catch(e) {
		log('Failed to invoke memory probing: %s\n', e);
	}
}

// Main function to perform interface health checks
function perform_interface_health_checks(configs) {
	let interfaces = ubus.call('network.interface', 'dump').interface;
	let count = 0;

	for (let iface in interfaces) {
		let name = iface.interface;
		if (name == 'loopback')
			continue;

		count++;

		let combined_health = {};
		let all_warnings = [];

		// Perform individual health checks
		let dhcp_result = check_dhcp_health(iface, configs.health, configs.dhcp);
		let dns_result = check_dns_health(iface, configs.health, configs.dhcp);
		let wifi_result = check_wifi_health(iface, configs.wifi_config, configs.wifi_state);

		// Merge health results
		combined_health = { ...combined_health, ...dhcp_result.health };
		combined_health = { ...combined_health, ...dns_result.health };
		combined_health = { ...combined_health, ...wifi_result.health };

		// Merge warnings
		all_warnings = [ ...all_warnings, ...dhcp_result.warnings ];
		all_warnings = [ ...all_warnings, ...dns_result.warnings ];
		all_warnings = [ ...all_warnings, ...wifi_result.warnings ];

		// Store results if there are any health issues
		if (length(combined_health)) {
			combined_health.location = uci.get('network', name, 'ucentral_path');
			if (length(all_warnings))
				combined_health.warning = all_warnings;
			state.interfaces[name] = combined_health;
		}
	}

	return count;
}

// Main execution
function main() {
	// Load configurations
	let configs = load_configs();

	// Perform all health checks
	let interface_count = perform_interface_health_checks(configs);
	check_rrm_health(configs.rrmd_config);
	check_memory_health();

	// Check radio health
	let radio_issues = check_radio_health(configs.wifi_config, configs.wifi_state);
	if (length(radio_issues)) {
		state.radios = radio_issues;
		for (let radio_name, issue in radio_issues) {
			ubus.call('event', 'event', {
				object: 'health',
				verb: 'wifi',
				payload: {
					radio: radio_name,
					error: sprintf('Radio %s has failed SSIDs', radio_name),
					failed_ssids: issue.failed_ssids
				}
			});
		}
	}

	// Calculate and report sanity
	let errors = length(state.interfaces);
	if (!errors)
		delete state.interfaces;

	let radio_errors = length(radio_issues);

	let total_checks = interface_count + length(configs.wifi_config);
	let total_errors = errors + radio_errors;
	let sanity = 100 - (total_errors * 100 / (total_checks || 1));

	warn(printf('health check reports sanity of %d (iface_errors=%d, radio_errors=%d)', sanity, errors, radio_errors));
	ubus.call('ucentral', 'health', {sanity: sanity, data: state});

	let f = fs.open("/tmp/ucentral.health", "w");
	if (f) {
		f.write({sanity: sanity, data: state});
		f.close();
	}
}

// Execute main function
main();
