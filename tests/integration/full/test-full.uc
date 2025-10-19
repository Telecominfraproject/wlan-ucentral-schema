// Full configuration integration tests

"use strict";

import { FullIntegrationTestFramework } from '../../helpers/test-framework.uc';

export function run_tests() {
	let framework = FullIntegrationTestFramework(
		"Full Configuration Integration Tests",
		"integration/full"
	);
	
	let test_cases = [
		{
			name: "default-config",
			input: "input/default.json",
			output: "default.uci"
		}
	];
	
	let boards = ["eap101"];
	
	return framework.run_tests(test_cases, boards);
};