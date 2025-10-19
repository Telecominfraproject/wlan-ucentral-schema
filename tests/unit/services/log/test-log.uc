// Log service template unit tests

"use strict";

import { TestFramework, create_service_test_cases } from '../../../helpers/test-framework.uc';

export function run_tests() {
	let framework = TestFramework("../renderer/templates/services/log.uc", "Log Service Template Tests", "unit/services/log");
	let test_cases = create_service_test_cases("log", [
		"log-basic",
		"log-with-hostname"
	]);
	return framework.run_tests(test_cases);
};