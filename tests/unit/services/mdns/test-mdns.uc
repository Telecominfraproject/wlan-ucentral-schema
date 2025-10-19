// MDNS service template unit tests

"use strict";

import { TestFramework, create_service_test_cases } from '../../../helpers/test-framework.uc';

export function run_tests() {
	let framework = TestFramework("../renderer/templates/services/mdns.uc", "MDNS Service Template Tests", "unit/services/mdns");
	let test_cases = create_service_test_cases("mdns", [
		"mdns-basic",
		"mdns-no-interfaces",
		"mdns-single-interface",
		"mdns-fingerprint"
	]);
	return framework.run_tests(test_cases);
};