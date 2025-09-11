// NTP service template unit tests

"use strict";

import { TestFramework, create_service_test_cases } from '../../../helpers/test-framework.uc';

export function run_tests() {
	let framework = TestFramework("../renderer/templates/services/ntp.uc", "NTP Service Template Tests", "unit/services/ntp");
	let test_cases = create_service_test_cases("ntp", [
		"ntp-basic",
		"ntp-no-config",
		"ntp-no-interfaces",
		"ntp-single-interface"
	]);
	return framework.run_tests(test_cases);
};