// Realtime metrics template unit tests

"use strict";

import { TestFramework, create_metric_test_cases } from '../../../helpers/test-framework.uc';

export function run_tests() {
	let framework = TestFramework("../renderer/templates/metric/realtime.uc", "Realtime Metrics Template Tests", "unit/metrics/realtime");
	
	let test_cases = create_metric_test_cases("realtime", [
		"realtime-basic",
		"realtime-no-config",
		"realtime-empty-types",
		"realtime-filtered-events"
	]);
	
	return framework.run_tests(test_cases);
};