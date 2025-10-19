#!/usr/bin/env ucode

// Master test runner - imports and runs all unit tests

"use strict";

import * as fs from 'fs';

// Import all test modules
// Services
import { run_tests as admin_ui_tests } from './unit/services/admin_ui/test-admin_ui.uc';
import { run_tests as airtime_fairness_tests } from './unit/services/airtime_fairness/test-airtime_fairness.uc';
import { run_tests as captive_tests } from './unit/services/captive/test-captive.uc';
import { run_tests as dhcp_inject_tests } from './unit/services/dhcp_inject/test-dhcp_inject.uc';
import { run_tests as dhcp_relay_tests } from './unit/services/dhcp_relay/test-dhcp_relay.uc';
import { run_tests as dhcp_snooping_service_tests } from './unit/services/dhcp_snooping/test-dhcp_snooping.uc';
import { run_tests as fingerprint_tests } from './unit/services/fingerprint/test-fingerprint.uc';
import { run_tests as gps_tests } from './unit/services/gps/test-gps.uc';
import { run_tests as ieee8021x_tests } from './unit/services/ieee8021x/test-ieee8021x.uc';
import { run_tests as lldp_tests } from './unit/services/lldp/test-lldp.uc';
import { run_tests as log_tests } from './unit/services/log/test-log.uc';
import { run_tests as mdns_tests } from './unit/services/mdns/test-mdns.uc';
import { run_tests as ntp_tests } from './unit/services/ntp/test-ntp.uc';
import { run_tests as online_check_tests } from './unit/services/online_check/test-online_check.uc';
import { run_tests as quality_of_service_tests } from './unit/services/quality_of_service/test-quality_of_service.uc';
import { run_tests as radius_proxy_tests } from './unit/services/radius_proxy/test-radius_proxy.uc';
import { run_tests as rrm_tests } from './unit/services/rrm/test-rrm.uc';
import { run_tests as ssh_tests } from './unit/services/ssh/test-ssh.uc';

// Metrics
import { run_tests as dhcp_snooping_metric_tests } from './unit/metrics/dhcp_snooping/test-dhcp_snooping.uc';
import { run_tests as health_tests } from './unit/metrics/health/test-health.uc';
import { run_tests as realtime_tests } from './unit/metrics/realtime/test-realtime.uc';
import { run_tests as statistics_tests } from './unit/metrics/statistics/test-statistics.uc';
import { run_tests as telemetry_tests } from './unit/metrics/telemetry/test-telemetry.uc';
import { run_tests as wifi_frames_tests } from './unit/metrics/wifi_frames/test-wifi_frames.uc';
import { run_tests as wifi_scan_tests } from './unit/metrics/wifi_scan/test-wifi_scan.uc';

// Base templates
import { run_tests as unit_tests } from './unit/base/unit/test-unit.uc';
import { run_tests as timeout_tests } from './unit/base/timeout/test-timeout.uc';
import { run_tests as ethernet_tests } from './unit/base/ethernet/test-ethernet.uc';
import { run_tests as base_tests } from './unit/base/integration-base/test-base.uc';

// Integration tests
import { run_tests as full_tests } from './full/test-full.uc';

function repeat(str, count) {
	let result = "";
	for (let i = 0; i < count; i++) {
		result += str;
	}
	return result;
}

let total_results = {
	unit: {
		total_tests: 0,
		passed_tests: 0, 
		failed_tests: 0,
		test_suites: 0,
		passed_suites: 0,
		failed_suites: 0,
		failed_suite_names: []
	},
	integration: {
		total_tests: 0,
		passed_tests: 0, 
		failed_tests: 0,
		test_suites: 0,
		passed_suites: 0,
		failed_suites: 0,
		failed_suite_names: [],
		boards_tested: []
	}
};

function main() {
	printf("=== Template Test Suite Runner ===\n\n");
	
	let test_suites = [
		// Services
		{ name: "Admin UI Service", run_tests: admin_ui_tests },
		{ name: "Airtime Fairness Service", run_tests: airtime_fairness_tests },
		{ name: "Captive Service", run_tests: captive_tests },
		{ name: "DHCP Inject Service", run_tests: dhcp_inject_tests },
		{ name: "DHCP Relay Service", run_tests: dhcp_relay_tests },
		{ name: "DHCP Snooping Service", run_tests: dhcp_snooping_service_tests },
		{ name: "Fingerprint Service", run_tests: fingerprint_tests },
		{ name: "GPS Service", run_tests: gps_tests },
		{ name: "IEEE 802.1X Service", run_tests: ieee8021x_tests },
		{ name: "LLDP Service", run_tests: lldp_tests },
		{ name: "Log Service", run_tests: log_tests },
		{ name: "mDNS Service", run_tests: mdns_tests },
		{ name: "NTP Service", run_tests: ntp_tests },
		{ name: "Online Check Service", run_tests: online_check_tests },
		{ name: "Quality of Service", run_tests: quality_of_service_tests },
		{ name: "RADIUS Proxy Service", run_tests: radius_proxy_tests },
		{ name: "RRM Service", run_tests: rrm_tests },
		{ name: "SSH Service", run_tests: ssh_tests },
		
		// Metrics
		{ name: "DHCP Snooping Metrics", run_tests: dhcp_snooping_metric_tests },
		{ name: "Health Metrics", run_tests: health_tests },
		{ name: "Realtime Metrics", run_tests: realtime_tests },
		{ name: "Statistics Metrics", run_tests: statistics_tests },
		{ name: "Telemetry Metrics", run_tests: telemetry_tests },
		{ name: "WiFi Frames Metrics", run_tests: wifi_frames_tests },
		{ name: "WiFi Scan Metrics", run_tests: wifi_scan_tests },
		
		// Base templates
		{ name: "Unit Base Template", run_tests: unit_tests },
		{ name: "Timeout Base Template", run_tests: timeout_tests },
		{ name: "Ethernet Base Template", run_tests: ethernet_tests },
		{ name: "Base Template Unit Tests", run_tests: base_tests },

		// Integration tests
		{ name: "Full Integration", run_tests: full_tests, type: "integration", boards: ["eap101"] },
	];
	
	printf("Found %d test suites\n\n", length(test_suites));
	
	// Run each test suite
	for (let suite in test_suites) {
		let suite_type = suite.type || "unit";
		let target_results = total_results[suite_type];
		
		target_results.test_suites++;
		
		try {
			let results = suite.run_tests();
			
			// Aggregate results
			target_results.total_tests += results.passed + results.failed;
			target_results.passed_tests += results.passed;
			target_results.failed_tests += results.failed;
			
			// Track boards for integration tests
			if (suite_type == "integration" && suite.boards) {
				for (let board in suite.boards) {
					if (index(target_results.boards_tested, board) == -1) {
						push(target_results.boards_tested, board);
					}
				}
			}
			
			if (results.failed > 0) {
				target_results.failed_suites++;
				push(target_results.failed_suite_names, results.suite_name);
			} else {
				target_results.passed_suites++;
			}
			
		} catch (e) {
			printf("✗ ERROR in %s: %s\n", suite.name, e);
			target_results.failed_suites++;
			push(target_results.failed_suite_names, suite.name);
		}
		
		printf("\n");
	}
	
	// Print final summary
	printf("%s\n", repeat("=", 50));
	printf("=== FINAL RESULTS ===\n");
	
	// Unit test results
	printf("Unit tests: %d suites (%d passed, %d failed)\n", 
		total_results.unit.test_suites, total_results.unit.passed_suites, total_results.unit.failed_suites);
	printf("  Individual tests: %d total (%d passed, %d failed)\n", 
		total_results.unit.total_tests, total_results.unit.passed_tests, total_results.unit.failed_tests);
	
	// Integration test results
	if (total_results.integration.test_suites > 0) {
		printf("Integration tests: %d suites (%d passed, %d failed)\n", 
			total_results.integration.test_suites, total_results.integration.passed_suites, total_results.integration.failed_suites);
		printf("  Individual tests: %d total (%d passed, %d failed)\n", 
			total_results.integration.total_tests, total_results.integration.passed_tests, total_results.integration.failed_tests);
		printf("  Boards tested: %s\n", join(", ", total_results.integration.boards_tested));
	}
	
	// Overall totals
	let total_suites = total_results.unit.test_suites + total_results.integration.test_suites;
	let total_passed_suites = total_results.unit.passed_suites + total_results.integration.passed_suites;
	let total_failed_suites = total_results.unit.failed_suites + total_results.integration.failed_suites;
	let total_tests = total_results.unit.total_tests + total_results.integration.total_tests;
	let total_passed_tests = total_results.unit.passed_tests + total_results.integration.passed_tests;
	let total_failed_tests = total_results.unit.failed_tests + total_results.integration.failed_tests;
	
	printf("\nTotal: %d suites, %d tests (%d passed, %d failed)\n", 
		total_suites, total_tests, total_passed_tests, total_failed_tests);
	
	if (total_failed_suites > 0) {
		printf("\nFailed test suites:\n");
		for (let suite_name in total_results.unit.failed_suite_names) {
			printf("  - %s (unit)\n", suite_name);
		}
		for (let suite_name in total_results.integration.failed_suite_names) {
			printf("  - %s (integration)\n", suite_name);
		}
		exit(1);
	}
	
	printf("All test suites passed! 🎉\n");
}

main();