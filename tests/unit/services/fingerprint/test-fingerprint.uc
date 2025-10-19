// Fingerprint service template unit tests

"use strict";

import { TestFramework, create_service_test_cases } from '../../../helpers/test-framework.uc';

export function run_tests() {
	let framework = TestFramework("../renderer/templates/services/fingerprint.uc", "Fingerprint Service Template Tests", "unit/services/fingerprint");
	let test_cases = create_service_test_cases("fingerprint", [
		"fingerprint-basic",
		"fingerprint-custom",
		"fingerprint-disabled"
	]);
	return framework.run_tests(test_cases);
};