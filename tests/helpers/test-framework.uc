// Consolidated test framework for ucode template tests

"use strict";

import * as fs from 'fs';
import { create_test_context } from './mock-renderer.uc';

// Test framework class to consolidate common testing logic
export function TestFramework(template_path, test_title) {
    return {
        template_path: template_path,
        test_title: test_title,
        test_results: {
            passed: 0,
            failed: 0,
            errors: []
        },

        run_test: function(test_name, input_file, expected_file) {
            printf("Running test: %s\n", test_name);
            
            try {
                // Load test data
                let test_data = json(fs.readfile(input_file));
                let expected_output = fs.readfile(expected_file);
                
                // Handle empty expected files
                if (expected_output === null || expected_output === false) {
                    expected_output = "";
                }
                
                // Create test context (mock events already included by default)
                let context = create_test_context(test_data);
                
                // Add template vars to context
                for (let key, value in test_data.template_vars || {}) {
                    context[key] = value;
                }
                
                // Clear any previous generated files
                context.files.clear_generated_files();
                
                // Render template
                let abs_path = fs.realpath ? fs.realpath(this.template_path) : this.template_path;
                let output = render(abs_path, context);
                
                // Add generated files to output
                let generated_files = context.files.get_generated_files();
                for (let path, file_info in generated_files) {
                    output += sprintf("\n-----%s-----\n%s\n--------\n", path, file_info.content);
                }
                
                // Normalize whitespace for comparison
                output = trim(output);
                expected_output = trim(expected_output);
                
                // Compare output
                if (output == expected_output) {
                    printf("✓ PASS: %s\n", test_name);
                    this.test_results.passed++;
                } else {
                    printf("✗ FAIL: %s\n", test_name);
                    printf("Expected:\n%s\n", expected_output);
                    printf("Got:\n%s\n", output);
                    this.test_results.failed++;
                    push(this.test_results.errors, {
                        test: test_name,
                        expected: expected_output,
                        actual: output
                    });
                }
            } catch (e) {
                printf("✗ ERROR: %s - %s\n", test_name, e);
                this.test_results.failed++;
                push(this.test_results.errors, {
                    test: test_name,
                    error: e.message || e
                });
            }
            
            printf("\n");
        },

        run_tests: function(test_cases) {
            printf("=== %s ===\n\n", this.test_title);
            
            // Run all test cases
            for (let test_case in test_cases) {
                this.run_test(test_case.name, test_case.input, test_case.output);
            }
            
            // Print summary
            printf("=== Test Results ===\n");
            printf("Passed: %d\n", this.test_results.passed);
            printf("Failed: %d\n", this.test_results.failed);
            
            if (this.test_results.failed > 0) {
                printf("\nFailures:\n");
                for (let error in this.test_results.errors) {
                    printf("- %s\n", error.test);
                    if (error.error) {
                        printf("  Error: %s\n", error.error);
                    }
                }
                exit(1);
            }
            
            printf("All %s tests passed!\n", this.test_title);
        }
    };
};

// Helper function to create standard service test cases pattern
export function create_service_test_cases(service_name, test_names) {
    let test_cases = [];
    for (let test_name in test_names) {
        push(test_cases, {
            name: test_name,
            input: sprintf("input/%s.json", test_name),
            output: sprintf("output/%s.uci", test_name)
        });
    }
    return test_cases;
};

// Helper function to create standard metric test cases pattern  
export function create_metric_test_cases(metric_name, test_names) {
    let test_cases = [];
    for (let test_name in test_names) {
        push(test_cases, {
            name: test_name,
            input: sprintf("input/%s.json", test_name),
            output: sprintf("output/%s.uci", test_name)
        });
    }
    return test_cases;
};