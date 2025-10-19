#!/usr/bin/env ucode

// GPS service template unit tests

"use strict";

import { TestFramework, create_service_test_cases } from '../../../helpers/test-framework.uc';

function main() {
	let framework = TestFramework("../../../../renderer/templates/services/gps.uc", "GPS Service Template Tests");
	let test_cases = create_service_test_cases("gps", [
		"gps-basic",
		"gps-custom",
		"gps-disabled"
	]);
	framework.run_tests(test_cases);
}

main();