// Telemetry metrics template unit tests

"use strict";

import { TestFramework, create_metric_test_cases } from '../../../helpers/test-framework.uc';

export function run_tests() {
	let framework = TestFramework("../renderer/templates/metric/telemetry.uc", "Telemetry Metrics Template Tests", "unit/metrics/telemetry");
	
	let test_cases = create_metric_test_cases("telemetry", [
		"telemetry-basic",
		"telemetry-no-config",
		"telemetry-filtered-events",
		"telemetry-custom-interval",
		"telemetry-empty-types"
	]);
	
	return framework.run_tests(test_cases);
};