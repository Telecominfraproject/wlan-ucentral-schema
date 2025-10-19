#!/usr/bin/env ucode

// Fingerprint service template unit tests

"use strict";

import { TestFramework, create_service_test_cases } from '../../../helpers/test-framework.uc';

function main() {
	let framework = TestFramework("../../../../renderer/templates/services/fingerprint.uc", "Fingerprint Service Template Tests");
	let test_cases = create_service_test_cases("fingerprint", [
		"fingerprint-basic",
		"fingerprint-custom",
		"fingerprint-disabled"
	]);
	framework.run_tests(test_cases);
}

main();