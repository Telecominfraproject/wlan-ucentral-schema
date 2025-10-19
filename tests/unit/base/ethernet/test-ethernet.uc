// Ethernet base template unit tests

"use strict";

import { TestFramework, create_base_test_cases } from '../../../helpers/test-framework.uc';

export function run_tests() {
	let framework = TestFramework(
		"../renderer/templates/ethernet.uc",
		"Ethernet Base Template Tests",
		"unit/base/ethernet"
	);
	
	let test_cases = create_base_test_cases("ethernet", [
		"ethernet-basic",
		"ethernet-speed-duplex",
		"ethernet-disabled",
		"ethernet-wildcard"
	]);
	
	return framework.run_tests(test_cases);
};