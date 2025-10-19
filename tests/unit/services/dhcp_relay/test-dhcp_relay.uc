#!/usr/bin/env ucode

// DHCP Relay service template unit tests

"use strict";

import { TestFramework, create_service_test_cases } from '../../../helpers/test-framework.uc';

function main() {
	let framework = TestFramework("../../../../renderer/templates/services/dhcp_relay.uc", "DHCP Relay Service Template Tests");
	let test_cases = create_service_test_cases("dhcp_relay", [
		"dhcp_relay-basic",
		"dhcp_relay-no-service",
		"dhcp_relay-no-config",
		"dhcp_relay-no-interfaces"
	]);
	framework.run_tests(test_cases);
}

main();