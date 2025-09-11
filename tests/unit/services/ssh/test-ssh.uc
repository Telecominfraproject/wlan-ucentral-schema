#!/usr/bin/env ucode

// SSH service template unit tests

"use strict";

import { TestFramework, create_service_test_cases } from '../../../helpers/test-framework.uc';

function main() {
	let framework = TestFramework("../../../../renderer/templates/services/ssh.uc", "SSH Service Template Tests");
	
	let test_cases = create_service_test_cases("ssh", [
		"ssh-basic",
		"ssh-restricted", 
		"ssh-no-interfaces",
		"ssh-custom-port"
	]);
	
	framework.run_tests(test_cases);
}

main();