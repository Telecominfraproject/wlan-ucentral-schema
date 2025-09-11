#!/usr/bin/env ucode

// WiFi scan metrics template unit tests

"use strict";

import { TestFramework, create_metric_test_cases } from '../../../helpers/test-framework.uc';

function main() {
	let framework = TestFramework("../../../../renderer/templates/metric/wifi_scan.uc", "WiFi Scan Metrics Template Tests");
	
	let test_cases = create_metric_test_cases("wifi_scan", [
		"wifi-scan-basic",
		"wifi-scan-no-config",
		"wifi-scan-all-enabled",
		"wifi-scan-all-disabled",
		"wifi-scan-minimal"
	]);
	
	framework.run_tests(test_cases);
}

main();