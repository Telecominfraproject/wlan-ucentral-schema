#!/usr/bin/ucode
push(REQUIRE_SEARCH_PATH, '/usr/share/ucentral/*.uc');
let fs = require('fs');
let uci = require('uci');
let ubus = require('ubus');

state = {
	unit: {},
	interfaces: {}
};

let ctx = ubus.connect();
let interfaces = ctx.call('network.interface', 'dump').interface;
let cursor = uci.cursor();
cursor.load('health');
cursor.load('dhcp');
cursor.load('network');
cursor.load('wireless');
let config = cursor.get_all('state', 'health');
let dhcp = cursor.get_all('dhcp');
let wifi_config = cursor.get_all('wireless');
let wifi_state = require('wifi.iface');
let rrmd_config = cursor.get_all('rrmd');
let count = 0;

function find_ssid(ssid) {
	for (let name, iface in wifi_state)
		if (ssid == iface.ssid)
			return 0;
	return 1;
}

// Helper function: find SSID on a specific phy index
function find_ssid_on_phy(ssid, phy_idx, wifi_state) {
	for (let ifname, iface in wifi_state) {
		if (iface.ssid == ssid && iface.phy == phy_idx) {
			if (!iface.has_channel)
				return -1;
			return 0;
		}
	}
	return 1;
}

// Helper function: find SSID by interface name prefix
function find_ssid_by_prefix(ssid, prefix, wifi_state) {
	for (let ifname, iface in wifi_state) {
		if (iface.ssid == ssid && index(ifname, prefix) == 0) {
			if (!iface.has_channel)
				return -1;
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

		/* If interface has no channel, we can't verify band by frequency.
		 * Match it anyway — no_channel is the more useful error. */
		if (!iface.has_channel)
			return -1;

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

// Helper function: get radio match info from device config section
function get_radio_match_info(section) {
	if (!section || !section.path)
		return null;

	let info = {};

	/* If device has ifname_prefix, use prefix-based matching */
	if (section.ifname_prefix) {
		info.match_mode = 'prefix';
		info.ifname_prefix = section.ifname_prefix;
		return info;
	}

	/* Strip +N suffix used by multi-radio single-phy devices */
	let base_path = section.path;
	let path_match = match(base_path, /^(.+)\+([0-9]+)$/);
	if (path_match)
		base_path = path_match[1];

	/* Resolve phy from sysfs path */
	let phys = fs.glob(sprintf('/sys/devices/%s/ieee80211/phy*', base_path));
	if (!length(phys))
		phys = fs.glob(sprintf('/sys/devices/platform/%s/ieee80211/phy*', base_path));
	if (!length(phys))
		return null;

	sort(phys);

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

	/* Reconf-capable devices share one phy across bands; disambiguate by band */
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

// Health check: per-radio SSID presence
function check_radio_health(wifi_config, wifi_state) {
	let radio_issues = {};
	let radios_checked = 0;

	for (let k, section in wifi_config) {
		if (section['.type'] != 'wifi-device')
			continue;
		if (section.disabled == '1')
			continue;

		let dev_name = section['.name'];
		let match_info = get_radio_match_info(section);
		if (match_info == null)
			continue;

		let expected_ssids = [];
		for (let j, iface_section in wifi_config) {
			if (iface_section['.type'] != 'wifi-iface')
				continue;
			if (iface_section.device != dev_name)
				continue;
			/* Skip disabled, non-AP, or ssid-less ifaces */
			if (iface_section.disabled == '1')
				continue;
			if (iface_section.mode && iface_section.mode != 'ap')
				continue;
			if (!iface_section.ssid)
				continue;
			push(expected_ssids, iface_section.ssid);
		}

		if (!length(expected_ssids))
			continue;

		radios_checked++;

		let failed_ssids = {};
		for (let ssid in expected_ssids) {
			let result = find_ssid_for_radio(ssid, match_info, wifi_state);
			if (result != 0)
				failed_ssids[ssid] = (result == -1) ? 'no_channel' : 'missing';
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

	return { issues: radio_issues, checked: radios_checked };
}

function radius_probe(server, port, secret, user, pass)
{
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

	let f = fs.open('/tmp/radius.servers', 'w');
	if (f) {
		f.write(sprintf('%s %s\n', server, secret));
		f.close();
	}
	return system(['/usr/sbin/radiusprobe', user, pass]);
}

for (let iface in interfaces) {
	let name = iface.interface;
	if (name == 'loopback')
		continue;

	count++;

	let health = {};
	let ssid = {};
	let radius = {};
	let device = iface.l3_device || iface.interface;
	let warnings = [];

	let probe_dhcp = cursor.get('network', iface.interface, 'dhcp_healthcheck') || false;

	if (dhcp[name]?.leasetime && +config.dhcp_local)
		probe_dhcp = true;

	if (iface?.data.leasetime && +config.dhcp_remote)
		probe_dhcp = true;

	if (probe_dhcp) {
		let rc = system(['/usr/sbin/dhcpdiscover', '-i', device, '-t', '5']);
		if (rc) {
			health.dhcp = false;
			push(warnings, 'DHCP did not offer any leases');
			ctx.call('event', 'event',  { object: 'health', verb: 'dhcp', payload: { iface: name, error: 'DHCP did not offer any leases' }});
		}
	}

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
				ctx.call('event', 'event',  { object: 'health', verb: 'dns', payload: { iface: name, error: `DNS ${ip} is not reachable.` }});
			}
		}
	}

	for (let k, iface in wifi_config) {
		if (iface['.type'] != 'wifi-iface' || iface.network != name)
			continue;
		if (find_ssid(iface.ssid))
			ssid[iface.ssid] = false;
		if (iface.auth_server && iface.auth_port && iface.auth_secret && iface.health_username && iface.health_password && !iface.radius_gw_proxy)
			if (radius_probe(iface.auth_server, iface.auth_port, iface.auth_secret, iface.health_username, iface.health_password)) {
				radius[iface.ssid] = false;
				push(warnings, sprintf('Radius %s:%s is not reachable', iface.auth_server, iface.auth_port));
				ctx.call('event', 'event',  { object: 'health', verb: 'radius', payload: { ssid: iface.ssid, error: `Radius ${iface.auth_server}:${iface.auth_port} is not reachable` }});
			}
	}

	if (length(ssid))
		health.ssids = ssid;

	if (length(radius))
		health.radius = radius;

	if (length(health)) {
		health.location= cursor.get('network', name, 'ucentral_path');
		if (length(warnings))
			health.warning = warnings;
		state.interfaces[name] = health;
	}
}

let radio_result = check_radio_health(wifi_config, wifi_state);
let radio_issues = radio_result.issues;
let radios_checked = radio_result.checked;

if (length(radio_issues)) {
	state.radios = radio_issues;
	for (let radio_name, issue in radio_issues) {
		ctx.call('event', 'event', {
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

try {
	memory = ctx.call('system', 'info');
	memory = memory.memory;
	state.unit.memory =  100 - (memory.available * 100 / memory.total);
	if (state.unit.memory >= 90)
		ctx.call('event', 'event',  { object: 'health', verb: 'memory', payload: { used: state.unit.memory, error: 'Memory is almost exhausted.' }});
}
catch(e) {
	log('Failed to invoke memory probing: %s\n', e);
}

let iface_errors = length(state.interfaces);
if (!iface_errors)
	delete state.interfaces;

let radio_errors = length(radio_issues);

let total_checks = count + radios_checked;
let total_errors = iface_errors + radio_errors;
let sanity = 100 - (total_errors * 100 / (total_checks || 1));

warn(printf('health check reports sanity of %d (iface_errors=%d, radio_errors=%d)', sanity, iface_errors, radio_errors));
ctx.call('ucentral', 'health', {sanity: sanity, data: state});
let f = fs.open("/tmp/ucentral.health", "w");
if (f) {
	f.write({sanity: sanity, data: state});
	f.close();
}
