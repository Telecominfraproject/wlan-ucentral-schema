#!/usr/bin/env ucode

// Master test runner - discovers and runs all unit tests

"use strict";

import * as fs from 'fs';

function repeat(str, count) {
	let result = "";
	for (let i = 0; i < count; i++) {
		result += str;
	}
	return result;
}

let total_results = {
	passed: 0,
	failed: 0,
	test_suites: 0
};

function run_test_suite(test_script) {
	printf("Running test suite: %s\n", test_script);
	printf("%s\n", repeat("=", 50));
	
	let cmd = sprintf("cd %s && ucode %s", fs.dirname(test_script), fs.basename(test_script));
	let result = system(cmd);
	
	total_results.test_suites++;
	
	if (result == 0) {
		printf("✓ Test suite PASSED\n\n");
	} else {
		printf("✗ Test suite FAILED\n\n");
		total_results.failed++;
	}
	
	return result;
}

function discover_test_suites() {
	let test_suites = [];
	
	// Find all test-*.uc files in unit test directories
	for (let path in fs.glob("unit/services/*/test-*.uc")) {
		push(test_suites, path);
	}
	
	return test_suites;
}

function main() {
	printf("=== Template Test Suite Runner ===\n\n");
	
	let test_suites = discover_test_suites();
	
	if (length(test_suites) == 0) {
		printf("No test suites found!\n");
		exit(1);
	}
	
	printf("Found %d test suites:\n", length(test_suites));
	for (let suite in test_suites) {
		printf("  - %s\n", suite);
	}
	printf("\n");
	
	// Run each test suite
	let failed_suites = [];
	for (let suite in test_suites) {
		let result = run_test_suite(suite);
		if (result != 0) {
			push(failed_suites, suite);
		}
	}
	
	// Print final summary
	printf("%s\n", repeat("=", 50));
	printf("=== FINAL RESULTS ===\n");
	printf("Test suites run: %d\n", total_results.test_suites);
	printf("Passed: %d\n", total_results.test_suites - length(failed_suites));
	printf("Failed: %d\n", length(failed_suites));
	
	if (length(failed_suites) > 0) {
		printf("\nFailed test suites:\n");
		for (let suite in failed_suites) {
			printf("  - %s\n", suite);
		}
		exit(1);
	}
	
	printf("All test suites passed! 🎉\n");
}

main();