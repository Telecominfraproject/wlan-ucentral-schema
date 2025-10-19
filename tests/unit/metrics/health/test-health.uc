#!/usr/bin/env ucode

// Health metrics template unit tests

"use strict";

import { TestFramework, create_metric_test_cases } from '../../../helpers/test-framework.uc';

function main() {
	let framework = TestFramework("../../../../renderer/templates/metric/health.uc", "Health Metrics Template Tests");
	
	let test_cases = create_metric_test_cases("health", [
		"health-basic",
		"health-no-config",
		"health-all-disabled",
		"health-selective",
		"health-custom-interval"
	]);
	
	framework.run_tests(test_cases);
}

main();