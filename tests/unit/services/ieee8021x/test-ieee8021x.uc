// IEEE 802.1X service template unit tests

"use strict";

import { TestFramework, create_service_test_cases } from '../../../helpers/test-framework.uc';

export function run_tests() {
	let framework = TestFramework("../renderer/templates/services/ieee8021x.uc", "IEEE 802.1X Service Template Tests", "unit/services/ieee8021x");
	let test_cases = create_service_test_cases("ieee8021x", [
		"ieee8021x-radius",
		"ieee8021x-users",
		"ieee8021x-no-service",
		"ieee8021x-invalid-radius"
	]);
	return framework.run_tests(test_cases);
};