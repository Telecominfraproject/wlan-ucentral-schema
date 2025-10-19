#!/usr/bin/env ucode

// NTP service template unit tests

"use strict";

import { TestFramework, create_service_test_cases } from '../../../helpers/test-framework.uc';

function main() {
	let framework = TestFramework("../../../../renderer/templates/services/ntp.uc", "NTP Service Template Tests");
	let test_cases = create_service_test_cases("ntp", [
		"ntp-basic",
		"ntp-no-config",
		"ntp-no-interfaces",
		"ntp-single-interface"
	]);
	framework.run_tests(test_cases);
}

main();