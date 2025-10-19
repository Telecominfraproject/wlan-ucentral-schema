// Health metrics template unit tests

"use strict";

import { TestFramework, create_metric_test_cases } from '../../../helpers/test-framework.uc';

export function run_tests() {
	let framework = TestFramework("../renderer/templates/metric/health.uc", "Health Metrics Template Tests", "unit/metrics/health");
	
	let test_cases = create_metric_test_cases("health", [
		"health-basic",
		"health-no-config",
		"health-all-disabled",
		"health-selective",
		"health-custom-interval"
	]);
	
	return framework.run_tests(test_cases);
};