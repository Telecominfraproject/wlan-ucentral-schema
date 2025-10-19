#!/usr/bin/ucode

push(REQUIRE_SEARCH_PATH, '/usr/share/ucentral/*.uc');

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

	// Calculate and report sanity
	let errors = length(state.interfaces);
	if (!errors)
		delete state.interfaces;

	let sanity = 100 - (errors * 100 / interface_count);

	warn(printf('health check reports sanity of %d', sanity));
	ubus.call('ucentral', 'health', {sanity: sanity, data: state});
	
	let f = fs.open("/tmp/ucentral.health", "w");
	if (f) {
		f.write({sanity: sanity, data: state});
		f.close();
	}
}

// Execute main function
main();
