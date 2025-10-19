#!/usr/bin/env ucode

// Realtime metrics template unit tests

"use strict";

import { TestFramework, create_metric_test_cases } from '../../../helpers/test-framework.uc';

function main() {
	let framework = TestFramework("../../../../renderer/templates/metric/realtime.uc", "Realtime Metrics Template Tests");
	
	let test_cases = create_metric_test_cases("realtime", [
		"realtime-basic",
		"realtime-no-config",
		"realtime-empty-types",
		"realtime-filtered-events"
	]);
	
	framework.run_tests(test_cases);
}

main();