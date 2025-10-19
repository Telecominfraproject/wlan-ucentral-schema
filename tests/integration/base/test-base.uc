// Base template integration tests

"use strict";

import { IntegrationTestFramework } from '../../helpers/test-framework.uc';

export function run_tests() {
	let framework = IntegrationTestFramework(
		"../renderer/templates/base.uc",
		"Base Template Integration Tests",
		"integration/base"
	);
	
	let test_cases = [
		{
			name: "base-default",
			input: "input/base-default.json",
			output: "base-default.uci"
		}
	];
	
	let boards = ["eap101"];
	
	return framework.run_tests(test_cases, boards);
};