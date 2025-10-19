// Full configuration integration tests

"use strict";

import { FullIntegrationTestFramework } from '../helpers/test-framework.uc';

export function run_tests() {
	let framework = FullIntegrationTestFramework(
		"Full Configuration Integration Tests",
		"full"
	);
	
	// Generate test cases for all example files
	let example_files = [
		"admin_ui", "big", "block-rfc1918", "captive-click", "captive-credentials", "captive",
		"captive-multiple", "captive-radius", "captive-uam", "captive-webroot", "crypto-enterprise",
		"crypto-psk", "data-plane", "default", "dhcp-relay", "dhcpsnoop", "dual-stack", "eap_local",
		"fingerprint-final-always", "fingerprint-final-periodic", "fingerprint-raw", "gps",
		"ieee8021x-mac-auth", "ieee8021x-nat", "ieee8021x-radius", "igmp", "lldp",
		"loop-detect", "maverick", "mesh", "metrics", "multi-psk", "ntp", "online-check", "owe",
		"owe-transition", "psk2-radius", "qos-class", "qos", "quality-threshold", "radius-gw-proxy",
		"radius", "radius-proxy", "radius-request-attr", "radius-secondary", "rate-limit",
		"roaming-psk2-radius", "rrm", "ssh", "strict-forwarding", "switch-fabric",
		"switch-ports", "switch-vlan", "telemetry", "tip-oui", "unit", "vlan", "wds-ap",
		"wds-sta", "wifi-6e-afc", "wifi-6e", "wifi-6e-mpsk", "wifi-6e-mpsk-radius",
		"wifi-6e-psk2-radius", "wifi-7", "wpa2-radius", "wwan"
	];

	let test_cases = [];
	for (let example in example_files) {
		push(test_cases, {
			name: example + "-config",
			input: sprintf("input/%s.json", example),
			output: sprintf("%s.uci", example)
		});
	}
	
	let boards = ["eap101"];
	
	return framework.run_tests(test_cases, boards);
};
