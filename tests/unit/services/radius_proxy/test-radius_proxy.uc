// RADIUS Proxy service template unit tests

"use strict";

import { TestFramework, create_service_test_cases } from '../../../helpers/test-framework.uc';

export function run_tests() {
	let framework = TestFramework("../renderer/templates/services/radius_proxy.uc", "RADIUS Proxy Service Template Tests", "unit/services/radius_proxy");
	let test_cases = create_service_test_cases("radius_proxy", [
		"radius-proxy-radsec",
		"radius-proxy-radius",
		"radius-proxy-block",
		"radius-proxy-mixed",
		"radius-proxy-disabled"
	]);
	return framework.run_tests(test_cases);
};