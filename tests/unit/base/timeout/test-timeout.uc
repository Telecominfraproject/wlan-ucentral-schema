// Timeout base template unit tests

"use strict";

import { TestFramework, create_base_test_cases } from '../../../helpers/test-framework.uc';

export function run_tests() {
	let framework = TestFramework(
		"../renderer/templates/timeout.uc",
		"Timeout Base Template Tests",
		"unit/base/timeout"
	);
	
	let test_cases = create_base_test_cases("timeout", [
		"timeout-all",
		"timeout-offline-only",
		"timeout-orphan-only",
		"timeout-validate-only",
		"timeout-empty",
		"timeout-mixed"
	]);
	
	return framework.run_tests(test_cases);
};