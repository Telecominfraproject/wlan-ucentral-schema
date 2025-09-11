// WiFi scan metrics template unit tests

"use strict";

import { TestFramework, create_metric_test_cases } from '../../../helpers/test-framework.uc';

export function run_tests() {
	let framework = TestFramework("../renderer/templates/metric/wifi_scan.uc", "WiFi Scan Metrics Template Tests", "unit/metrics/wifi_scan");
	
	let test_cases = create_metric_test_cases("wifi_scan", [
		"wifi-scan-basic",
		"wifi-scan-no-config",
		"wifi-scan-all-enabled",
		"wifi-scan-all-disabled",
		"wifi-scan-minimal"
	]);
	
	return framework.run_tests(test_cases);
};