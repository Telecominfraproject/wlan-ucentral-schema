// GPS service template unit tests

"use strict";

import { TestFramework, create_service_test_cases } from '../../../helpers/test-framework.uc';

export function run_tests() {
	let framework = TestFramework("../renderer/templates/services/gps.uc", "GPS Service Template Tests", "unit/services/gps");
	let test_cases = create_service_test_cases("gps", [
		"gps-basic",
		"gps-custom",
		"gps-disabled"
	]);
	return framework.run_tests(test_cases);
};