// Unit base template unit tests

"use strict";

import { TestFramework, create_base_test_cases } from '../../../helpers/test-framework.uc';

export function run_tests() {
	let framework = TestFramework(
		"../renderer/templates/unit.uc",
		"Unit Base Template Tests",
		"unit/base/unit"
	);
	
	let test_cases = create_base_test_cases("unit", [
		"unit-basic",
		"unit-minimal",
		"unit-system-password",
		"unit-random-password",
		"unit-leds-off",
		"unit-full"
	]);
	
	return framework.run_tests(test_cases);
};