#!/usr/bin/env ucode

// Online Check service template unit tests

"use strict";

import { TestFramework, create_service_test_cases } from '../../../helpers/test-framework.uc';

function main() {
	let framework = TestFramework("../../../../renderer/templates/services/online_check.uc", "Online Check Service Template Tests");
	let test_cases = create_service_test_cases("online_check", [
		"online-check-ping-only",
		"online-check-download-only",
		"online-check-combined",
		"online-check-disabled"
	]);
	framework.run_tests(test_cases);
}

main();