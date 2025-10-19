#!/usr/bin/env ucode

// Airtime Fairness service template unit tests

"use strict";

import { TestFramework, create_service_test_cases } from '../../../helpers/test-framework.uc';

function main() {
	let framework = TestFramework("../../../../renderer/templates/services/airtime_fairness.uc", "Airtime Fairness Service Template Tests");
	let test_cases = create_service_test_cases("airtime_fairness", [
		"airtime-fairness-basic",
		"airtime-fairness-custom",
		"airtime-fairness-disabled"
	]);
	framework.run_tests(test_cases);
}

main();