// Captive service template unit tests

"use strict";

import { TestFramework, create_service_test_cases } from '../../../helpers/test-framework.uc';

export function run_tests() {
	let framework = TestFramework("../renderer/templates/services/captive.uc", "Captive Service Template Tests", "unit/services/captive");
	let test_cases = create_service_test_cases("captive", [
		"captive-basic",
		"captive-credentials",
		"captive-radius",
		"captive-no-service",
		"captive-no-ssids",
		"captive-multiple-interfaces",
		"captive-upstream"
	]);
	return framework.run_tests(test_cases);
};