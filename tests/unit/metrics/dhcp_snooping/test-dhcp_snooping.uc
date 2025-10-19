// DHCP snooping metrics template unit tests

"use strict";

import { TestFramework, create_metric_test_cases } from '../../../helpers/test-framework.uc';

export function run_tests() {
	let framework = TestFramework("../renderer/templates/metric/dhcp_snooping.uc", "DHCP Snooping Metrics Template Tests", "unit/metrics/dhcp_snooping");
	
	let test_cases = create_metric_test_cases("dhcp_snooping", [
		"dhcp-snooping-basic",
		"dhcp-snooping-no-service",
		"dhcp-snooping-all-filters",
		"dhcp-snooping-multiple-interfaces",
		"dhcp-snooping-single-filter"
	]);
	
	return framework.run_tests(test_cases);
};