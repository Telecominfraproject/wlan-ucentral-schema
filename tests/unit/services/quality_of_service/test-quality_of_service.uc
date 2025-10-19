// Quality of Service template unit tests

"use strict";

import { TestFramework, create_service_test_cases } from '../../../helpers/test-framework.uc';

export function run_tests() {
	let framework = TestFramework("../renderer/templates/services/quality_of_service.uc", "Quality of Service Template Tests", "unit/services/quality_of_service");
	let test_cases = create_service_test_cases("quality_of_service", [
		"qos-basic",
		"qos-services",
		"qos-complex",
		"qos-disabled"
	]);
	return framework.run_tests(test_cases);
};