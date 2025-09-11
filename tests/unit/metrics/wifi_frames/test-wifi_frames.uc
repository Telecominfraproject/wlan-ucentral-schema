// WiFi frames metrics template unit tests

"use strict";

import { TestFramework, create_metric_test_cases } from '../../../helpers/test-framework.uc';

export function run_tests() {
	let framework = TestFramework("../renderer/templates/metric/wifi_frames.uc", "WiFi Frames Metrics Template Tests", "unit/metrics/wifi_frames");
	
	let test_cases = create_metric_test_cases("wifi_frames", [
		"wifi-frames-basic",
		"wifi-frames-no-config",
		"wifi-frames-single-filter",
		"wifi-frames-all-types",
		"wifi-frames-empty-filters",
		"wifi-frames-security-events"
	]);
	
	return framework.run_tests(test_cases);
};