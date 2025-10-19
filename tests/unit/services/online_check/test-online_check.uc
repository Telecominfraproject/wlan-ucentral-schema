// Online Check service template unit tests

"use strict";

import { TestFramework, create_service_test_cases } from '../../../helpers/test-framework.uc';

export function run_tests() {
	let framework = TestFramework("../renderer/templates/services/online_check.uc", "Online Check Service Template Tests", "unit/services/online_check");
	let test_cases = create_service_test_cases("online_check", [
		"online-check-ping-only",
		"online-check-download-only",
		"online-check-combined",
		"online-check-disabled"
	]);
	return framework.run_tests(test_cases);
};