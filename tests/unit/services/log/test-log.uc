#!/usr/bin/env ucode

// Log service template unit tests

"use strict";

import { TestFramework, create_service_test_cases } from '../../../helpers/test-framework.uc';

function main() {
	let framework = TestFramework("../../../../renderer/templates/services/log.uc", "Log Service Template Tests");
	let test_cases = create_service_test_cases("log", [
		"log-basic",
		"log-with-hostname"
	]);
	framework.run_tests(test_cases);
}

main();