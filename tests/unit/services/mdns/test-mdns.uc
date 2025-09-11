#!/usr/bin/env ucode

// MDNS service template unit tests

"use strict";

import { TestFramework, create_service_test_cases } from '../../../helpers/test-framework.uc';

function main() {
	let framework = TestFramework("../../../../renderer/templates/services/mdns.uc", "MDNS Service Template Tests");
	let test_cases = create_service_test_cases("mdns", [
		"mdns-basic",
		"mdns-no-interfaces",
		"mdns-single-interface",
		"mdns-fingerprint"
	]);
	framework.run_tests(test_cases);
}

main();