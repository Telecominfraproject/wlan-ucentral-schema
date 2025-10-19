// Admin UI service template unit tests

"use strict";

import { TestFramework, create_service_test_cases } from '../../../helpers/test-framework.uc';

export function run_tests() {
	let framework = TestFramework("../renderer/templates/admin_ui.uc", "Admin UI Service Template Tests", "unit/services/admin_ui");
	
	let test_cases = create_service_test_cases("admin_ui", [
		"admin-ui-basic",
		"admin-ui-with-key",
		"admin-ui-custom-bands", 
		"admin-ui-full-config",
		"admin-ui-no-service"
	]);
	
	return framework.run_tests(test_cases);
};