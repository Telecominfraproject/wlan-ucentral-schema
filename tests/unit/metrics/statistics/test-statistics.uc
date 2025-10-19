// Statistics metrics template unit tests

"use strict";

import { TestFramework, create_metric_test_cases } from '../../../helpers/test-framework.uc';

export function run_tests() {
	let framework = TestFramework("../renderer/templates/metric/statistics.uc", "Statistics Metrics Template Tests", "unit/metrics/statistics");
	
	let test_cases = create_metric_test_cases("statistics", [
		"statistics-basic",
		"statistics-no-config",
		"statistics-all-types",
		"statistics-custom-interval",
		"statistics-empty-types"
	]);
	
	return framework.run_tests(test_cases);
};