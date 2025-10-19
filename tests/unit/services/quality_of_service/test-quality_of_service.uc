#!/usr/bin/env ucode

// Quality of Service template unit tests

"use strict";

import { TestFramework, create_service_test_cases } from '../../../helpers/test-framework.uc';

function main() {
	let framework = TestFramework("../../../../renderer/templates/services/quality_of_service.uc", "Quality of Service Template Tests");
	let test_cases = create_service_test_cases("quality_of_service", [
		"qos-basic",
		"qos-services",
		"qos-complex",
		"qos-disabled"
	]);
	framework.run_tests(test_cases);
}

main();