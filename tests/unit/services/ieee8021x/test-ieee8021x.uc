#!/usr/bin/env ucode

// IEEE 802.1X service template unit tests

"use strict";

import * as fs from 'fs';
import { create_test_context } from '../../../helpers/mock-renderer.uc';

let test_results = {
	passed: 0,
	failed: 0,
	errors: []
};

function run_test(test_name, input_file, expected_file) {
	printf("Running test: %s\n", test_name);
	
	try {
		// Load test data
		let test_data = json(fs.readfile(input_file));
		let expected_output = fs.readfile(expected_file);
		
		// Handle empty expected files
		if (expected_output === null || expected_output === false) {
			expected_output = "";
		}
		
		// Create test context
		let context = create_test_context(test_data);
		
		// Add template vars to context
		for (let key, value in test_data.template_vars || {}) {
			context[key] = value;
		}
		
		// Render template
		let output = render("../../../../renderer/templates/services/ieee8021x.uc", context);
		
		// Normalize whitespace for comparison
		output = trim(replace(output, /\n\s*\n/g, '\n'));
		expected_output = trim(replace(expected_output, /\n\s*\n/g, '\n'));
		
		// Compare output
		if (output == expected_output) {
			printf("✓ PASS: %s\n", test_name);
			test_results.passed++;
		} else {
			printf("✗ FAIL: %s\n", test_name);
			printf("Expected:\n%s\n", expected_output);
			printf("Got:\n%s\n", output);
			test_results.failed++;
			push(test_results.errors, {
				test: test_name,
				expected: expected_output,
				actual: output
			});
		}
	} catch (e) {
		printf("✗ ERROR: %s - %s\n", test_name, e);
		test_results.failed++;
		push(test_results.errors, {
			test: test_name,
			error: e.message || e
		});
	}
	
	printf("\n");
}

function main() {
	printf("=== IEEE 802.1X Service Template Tests ===\n\n");
	
	// Run all test cases
	run_test("ieee8021x-radius", "input/ieee8021x-radius.json", "output/ieee8021x-radius.uci");
	run_test("ieee8021x-users", "input/ieee8021x-users.json", "output/ieee8021x-users.uci");
	run_test("ieee8021x-no-service", "input/ieee8021x-no-service.json", "output/ieee8021x-no-service.uci");
	run_test("ieee8021x-invalid-radius", "input/ieee8021x-invalid-radius.json", "output/ieee8021x-invalid-radius.uci");
	
	// Print summary
	printf("=== Test Results ===\n");
	printf("Passed: %d\n", test_results.passed);
	printf("Failed: %d\n", test_results.failed);
	
	if (test_results.failed > 0) {
		printf("\nFailures:\n");
		for (let error in test_results.errors) {
			printf("- %s\n", error.test);
			if (error.error) {
				printf("  Error: %s\n", error.error);
			}
		}
		exit(1);
	}
	
	printf("All IEEE 802.1X service tests passed!\n");
}

main();