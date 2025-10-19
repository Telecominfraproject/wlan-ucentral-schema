#!/usr/bin/env ucode

// LLDP service template unit tests

"use strict";

import { TestFramework, create_service_test_cases } from '../../../helpers/test-framework.uc';

function main() {
	let framework = TestFramework("../../../../renderer/templates/services/lldp.uc", "LLDP Service Template Tests");
	let test_cases = create_service_test_cases("lldp", [
		"lldp-basic",
		"lldp-no-service",
		"lldp-multiple-interfaces"
	]);
	framework.run_tests(test_cases);
}

main();