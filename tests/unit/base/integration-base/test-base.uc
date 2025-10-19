// Base template unit tests

"use strict";

import { TestFramework, create_base_test_cases } from '../../../helpers/test-framework.uc';

export function run_tests() {
	let framework = TestFramework(
		"../renderer/templates/base.uc",
		"Base Template Unit Tests",
		"unit/base/integration-base"
	);

	let test_cases = create_base_test_cases("base", [
		"base-default"
	]);

	return framework.run_tests(test_cases);
};