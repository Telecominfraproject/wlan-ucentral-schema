// RRM service template unit tests

"use strict";

import { TestFramework, create_service_test_cases } from '../../../helpers/test-framework.uc';

export function run_tests() {
	let framework = TestFramework("../renderer/templates/services/rrm.uc", "RRM Service Template Tests", "unit/services/rrm");
	
	let test_cases = create_service_test_cases("rrm", [
		"rrm-basic",
		"rrm-no-service",
		"rrm-minimal", 
		"rrm-chanutil-only",
		"rrm-custom-settings"
	]);
	
	return framework.run_tests(test_cases);
};