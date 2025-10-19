#!/usr/bin/env ucode

// DHCP Snooping service template unit tests

"use strict";

import { TestFramework, create_service_test_cases } from '../../../helpers/test-framework.uc';

function main() {
	let framework = TestFramework("../../../../renderer/templates/services/dhcp_snooping.uc", "DHCP Snooping Service Template Tests");
	let test_cases = create_service_test_cases("dhcp_snooping", [
		"dhcp-snooping-basic",
		"dhcp-snooping-upstream-downstream",
		"dhcp-snooping-vlans"
	]);
	framework.run_tests(test_cases);
}

main();