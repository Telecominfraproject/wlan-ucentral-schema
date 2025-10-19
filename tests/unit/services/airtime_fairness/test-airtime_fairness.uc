// Airtime Fairness service template unit tests

"use strict";

import { TestFramework, create_service_test_cases } from '../../../helpers/test-framework.uc';

export function run_tests() {
	let framework = TestFramework("../renderer/templates/services/airtime_fairness.uc", "Airtime Fairness Service Template Tests", "unit/services/airtime_fairness");
	let test_cases = create_service_test_cases("airtime_fairness", [
		"airtime-fairness-basic",
		"airtime-fairness-custom",
		"airtime-fairness-disabled"
	]);
	return framework.run_tests(test_cases);
};