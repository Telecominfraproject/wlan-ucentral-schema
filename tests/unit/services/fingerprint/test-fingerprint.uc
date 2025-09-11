#!/usr/bin/env ucode

// Fingerprint service template unit tests

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
		
		// Clear any previous generated files
		context.files.clear_generated_files();
		
		// Render template
		let output = render("../../../../renderer/templates/services/fingerprint.uc", context);
		
		// Add generated files to output
		let generated_files = context.files.get_generated_files();
		for (let path, file_info in generated_files) {
			output += sprintf("\n-----%s-----\n%s\n--------\n", path, file_info.content);
		}
		
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
	printf("=== Fingerprint Service Template Tests ===\n\n");
	
	// Run all test cases
	run_test("fingerprint-basic", "input/fingerprint-basic.json", "output/fingerprint-basic.uci");
	run_test("fingerprint-custom", "input/fingerprint-custom.json", "output/fingerprint-custom.uci");
	run_test("fingerprint-disabled", "input/fingerprint-disabled.json", "output/fingerprint-disabled.uci");
	
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
	
	printf("All Fingerprint service tests passed!\n");
}

main();