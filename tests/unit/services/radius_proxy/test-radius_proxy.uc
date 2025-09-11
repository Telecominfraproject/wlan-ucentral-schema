#!/usr/bin/env ucode

// RADIUS Proxy service template unit tests

"use strict";

import { TestFramework, create_service_test_cases } from '../../../helpers/test-framework.uc';

function main() {
	let framework = TestFramework("../../../../renderer/templates/services/radius_proxy.uc", "RADIUS Proxy Service Template Tests");
	let test_cases = create_service_test_cases("radius_proxy", [
		"radius-proxy-radsec",
		"radius-proxy-radius",
		"radius-proxy-block",
		"radius-proxy-mixed",
		"radius-proxy-disabled"
	]);
	framework.run_tests(test_cases);
}

main();