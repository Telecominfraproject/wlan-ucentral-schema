// Consolidated test framework for ucode template tests

"use strict";

import * as fs from 'fs';
import { create_test_context, create_board_test_context, create_full_test_context } from './mock-renderer.uc';
import { validate } from './schemareader.uc';
import {
	mock_toplevel, report_test_pass, report_test_fail, report_test_error,
	create_diff_files, load_test_files, load_test_board_data,
	process_test_output, format_test_suite_results
} from './test-utils.uc';

// Test framework class to consolidate common testing logic
export function TestFramework(template_path, test_title, test_dir) {
    return {
        template_path: template_path,
        test_title: test_title,
        test_dir: test_dir || ".",
        test_results: {
            passed: 0,
            failed: 0,
            errors: []
        },

        run_test: function(test_name, input_file, expected_file) {
            printf("Running test: %s\n", test_name);

            try {
                // Load test files using shared utility
                let test_files = load_test_files(this.test_dir, input_file, expected_file);
                let test_data = test_files.test_data;
                let expected_output = test_files.expected_output;

                // Initialize state like toplevel.uc does
                mock_toplevel(test_data);

                // Create test context (mock events already included by default)
                let context = create_test_context(test_data);

                // Add template vars to context
                for (let key, value in test_data.template_vars || {}) {
                    context[key] = value;
                }

                // Process test output using shared utility
                let output = process_test_output(context, this.template_path, test_name, this.test_dir);

                // Normalize expected output for comparison
                expected_output = trim(expected_output);

                // Compare output
                if (output == expected_output) {
                    report_test_pass(test_name);
                    this.test_results.passed++;
                } else {
                    report_test_fail(test_name);
                    create_diff_files(test_name, null, expected_output, output);

                    this.test_results.failed++;
                    push(this.test_results.errors, {
                        test: test_name,
                        expected: expected_output,
                        actual: output
                    });
                }
            } catch (e) {
                report_test_error(test_name, null, e);
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

            // Format and return results using shared utility
            return format_test_suite_results(this.test_results, this.test_title);
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

// Helper function to create standard base template test cases pattern
export function create_base_test_cases(template_name, test_names) {
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
// Integration test framework for board-specific tests
export function IntegrationTestFramework(template_path, test_title, test_dir) {
    return {
        template_path: template_path,
        test_title: test_title,
        test_dir: test_dir || ".",
        test_results: { passed: 0, failed: 0, errors: [] },
        
        run_board_test: function(test_name, input_file, board_name, expected_file) {
            printf("Running test: %s (board: %s)\n", test_name, board_name);

            try {
                // Load test files and board data using shared utilities
                let test_files = load_test_files(this.test_dir, input_file, expected_file, board_name);
                let test_data = test_files.test_data;
                let expected_output = test_files.expected_output;
                let board_info = load_test_board_data(board_name);
                let board_data = board_info.board_data;
                let capabilities = board_info.capabilities;

                // Create board test context
                let context = create_board_test_context(test_data, board_data, capabilities, board_name);

                // Add template vars to context
                for (let key, value in test_data.template_vars || {}) {
                    context[key] = value;
                }

                // Process test output using shared utility
                let output = process_test_output(context, this.template_path, test_name, this.test_dir, board_name);

                // Normalize expected output for comparison
                expected_output = trim(expected_output);

                // Compare output
                if (output == expected_output) {
                    report_test_pass(test_name, board_name);
                    this.test_results.passed++;
                } else {
                    report_test_fail(test_name, board_name);
                    create_diff_files(test_name, board_name, expected_output, output);
                    this.test_results.failed++;
                }
            } catch (e) {
                report_test_error(test_name, board_name, e);
                this.test_results.failed++;
            }

            printf("\n");
        },
        
        run_tests: function(test_cases, boards) {
            printf("=== %s ===\n\n", this.test_title);

            this.test_results = { passed: 0, failed: 0, errors: [] };

            for (let test_case in test_cases) {
                for (let board in boards) {
                    this.run_board_test(test_case.name, test_case.input, board, test_case.output);
                }
            }

            // Format and return results using shared utility
            return format_test_suite_results(this.test_results, this.test_title);
        }
    };
};

// Full integration test framework for complete configuration testing
export function FullIntegrationTestFramework(test_title, test_dir) {
    return {
        test_title: test_title,
        test_dir: test_dir || ".",
        test_results: { passed: 0, failed: 0, errors: [] },
        
        run_full_test: function(test_name, input_file, board_name, expected_file) {
            printf("Running full test: %s (board: %s)\n", test_name, board_name);

            try {
                // Load expected output using shared utility (simpler path handling)
                let test_files = load_test_files(this.test_dir, input_file, expected_file, board_name);
                let expected_output = test_files.expected_output;

                // Use separate process to avoid file descriptor leaks
                // Combine stdout and stderr to see all output including errors
                let cmd = sprintf("ucode helpers/run-single-integration-test.uc '%s' '%s' '%s' '%s' 2>&1",
                                this.test_dir, input_file, board_name, expected_file);

                let proc = fs.popen(cmd);
                if (!proc) {
                    report_test_error(test_name, board_name, "Failed to start test process");
                    this.test_results.failed++;
                    return;
                }

                let actual_output = proc.read("all");
                let exit_code = proc.close();

                if (exit_code !== 0) {
                    let error_msg = sprintf("Process failed with code %d", exit_code);
                    report_test_error(test_name, board_name, error_msg);
                    printf("Process output:\n%s\n", actual_output);
                    this.test_results.failed++;
                    return;
                }

                // Compare output using normalized comparison
                actual_output = trim(actual_output);
                expected_output = trim(expected_output);

                if (actual_output == expected_output) {
                    report_test_pass(test_name, board_name);
                    this.test_results.passed++;
                } else {
                    report_test_fail(test_name, board_name);
                    create_diff_files(test_name, board_name, expected_output, actual_output);
                    this.test_results.failed++;
                }

            } catch (e) {
                report_test_error(test_name, board_name, e);
                this.test_results.failed++;
            }

            printf("\n");
        },
        
        run_tests: function(test_cases, boards) {
            printf("=== %s ===\n\n", this.test_title);

            this.test_results = { passed: 0, failed: 0, errors: [] };

            for (let test_case in test_cases) {
                for (let board in boards) {
                    this.run_full_test(test_case.name, test_case.input, board, test_case.output);
                }
            }

            // Format and return results using shared utility
            return format_test_suite_results(this.test_results, this.test_title);
        }
    };
};
