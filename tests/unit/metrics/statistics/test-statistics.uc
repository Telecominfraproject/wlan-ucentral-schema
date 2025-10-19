#!/usr/bin/env ucode

// Statistics metrics template unit tests

"use strict";

import { TestFramework, create_metric_test_cases } from '../../../helpers/test-framework.uc';

function main() {
	let framework = TestFramework("../../../../renderer/templates/metric/statistics.uc", "Statistics Metrics Template Tests");
	
	let test_cases = create_metric_test_cases("statistics", [
		"statistics-basic",
		"statistics-no-config",
		"statistics-all-types",
		"statistics-custom-interval",
		"statistics-empty-types"
	]);
	
	framework.run_tests(test_cases);
}

main();