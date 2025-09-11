#!/usr/bin/env ucode

// DHCP Inject service template unit tests

"use strict";

import { TestFramework, create_service_test_cases } from '../../../helpers/test-framework.uc';

function main() {
	let framework = TestFramework("../../../../renderer/templates/services/dhcp_inject.uc", "DHCP Inject Service Template Tests");
	let test_cases = create_service_test_cases("dhcp_inject", [
		"dhcp_inject-basic",
		"dhcp_inject-no-config",
		"dhcp_inject-no-ssids",
		"dhcp_inject-default-ports"
	]);
	framework.run_tests(test_cases);
}

main();