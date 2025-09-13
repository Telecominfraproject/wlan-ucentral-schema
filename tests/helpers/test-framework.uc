// Consolidated test framework for ucode template tests

"use strict";

import * as fs from 'fs';
import { create_test_context, create_board_test_context, create_full_test_context } from './mock-renderer.uc';
import { validate } from './schemareader.uc';

// Mock toplevel initialization logic - moved from mock-renderer.uc
function mock_toplevel(state) {
    // Initialize interfaces array if it doesn't exist
    if (!state.interfaces) {
        state.interfaces = [];
    }

    // Initialize VLAN properties like toplevel.uc does
    let vlans = [];
    for (let i, interface in state.interfaces) {
        interface.index = i; // Set interface index

        // Note: We'll rely on the real ethernet mock for VLAN logic
        if (!interface.vlan) {
            interface.vlan = { id: 0 }; // Default VLAN like toplevel.uc
        }
    }
}

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
                // Load test data (paths relative to test directory)
                let input_path = sprintf("%s/%s", this.test_dir, input_file);
                let output_path = sprintf("%s/%s", this.test_dir, expected_file);
                let raw_input = fs.readfile(input_path);
                let test_data = json(raw_input);
                let expected_output = fs.readfile(output_path);
                
                // Handle empty expected files
                if (expected_output === null || expected_output === false) {
                    expected_output = "";
                }
              
                // Initialize state like toplevel.uc does
		mock_toplevel(test_data);

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
                
                // Write debug output to /tmp/ucentral-test-output/
                context.files.write_debug_output(this.test_dir + "/" + test_name, output);
                
                // Normalize whitespace for comparison
                output = trim(output);
                expected_output = trim(expected_output);
                
                // Compare output
                if (output == expected_output) {
                    printf("✓ PASS: %s\n", test_name);
                    this.test_results.passed++;
                } else {
                    printf("✗ FAIL: %s\n", test_name);
                    // Create diff directory
                    try { fs.mkdir("/tmp/ucentral-test-diff"); } catch (e) {}
                    
                    // Write expected and actual to temp files for diff
                    let temp_expected = "/tmp/ucentral-test-diff/expected_" + test_name + ".uci";
                    let temp_actual = "/tmp/ucentral-test-diff/actual_" + test_name + ".uci";
                    let fd_exp = fs.open(temp_expected, "w");
                    if (fd_exp) { fd_exp.write(expected_output); fd_exp.close(); }
                    let fd_act = fs.open(temp_actual, "w");
                    if (fd_act) { fd_act.write(output); fd_act.close(); }
                    
                    // Show diff
                    let diff_cmd = sprintf("diff -u %s %s", temp_expected, temp_actual);
                    let diff_output = fs.popen(diff_cmd);
                    if (diff_output) {
                        let diff_result = diff_output.read("all");
                        diff_output.close();
                        printf("Diff:\n%s\n", diff_result);
                    }
                    
                    this.test_results.failed++;
                    push(this.test_results.errors, {
                        test: test_name,
                        expected: expected_output,
                        actual: output
                    });
                }
            } catch (e) {
                printf("✗ ERROR: %s - %s\n", test_name, e);
                if (e.stacktrace && e.stacktrace[0]?.context) {
                    printf("  Error: %s\n", e.stacktrace[0].context);
                }
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
            } else {
                printf("All %s tests passed!\n", this.test_title);
            }
            
            // Return results for aggregation
            return {
                passed: this.test_results.passed,
                failed: this.test_results.failed,
                errors: this.test_results.errors,
                suite_name: this.test_title
            };
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
                let input_path = sprintf("%s/%s", this.test_dir, input_file);
                let test_data = json(fs.readfile(input_path));

                let board_dir = sprintf("boards/%s", board_name);
                let board_data = json(fs.readfile(sprintf("%s/board.json", board_dir)));
                let capabilities = json(fs.readfile(sprintf("%s/capabilities.json", board_dir)));

                let output_path = sprintf("%s/output/%s/%s", this.test_dir, board_name, expected_file);
                let expected_output = fs.readfile(output_path);

                if (expected_output === null || expected_output === false) {
                    expected_output = "";
                }

                let context = create_board_test_context(test_data, board_data, capabilities, board_name);

                for (let key, value in test_data.template_vars || {}) {
                    context[key] = value;
                }
                
                context.files.clear_generated_files();
                
                let abs_path = fs.realpath ? fs.realpath(this.template_path) : this.template_path;
                let output = render(abs_path, context);
                
                let generated_files = context.files.get_generated_files();
                for (let path, file_info in generated_files) {
                    output += sprintf("\n-----%s-----\n%s\n--------\n", path, file_info.content);
                }
                
                // Write debug output to /tmp/ucentral-test-output/
                context.files.write_debug_output(test_name + "-" + board_name, output);
                
                output = trim(output);
                expected_output = trim(expected_output);
                
                if (output == expected_output) {
                    printf("✓ PASS: %s (%s)\n", test_name, board_name);
                    this.test_results.passed++;
                } else {
                    printf("✗ FAIL: %s (%s)\n", test_name, board_name);
                    // Create diff directory
                    try { fs.mkdir("/tmp/ucentral-test-diff"); } catch (e) {}
                    
                    // Write expected and actual to temp files for diff
                    let temp_expected = "/tmp/ucentral-test-diff/expected_" + test_name + "-" + board_name + ".uci";
                    let temp_actual = "/tmp/ucentral-test-diff/actual_" + test_name + "-" + board_name + ".uci";
                    let fd_exp = fs.open(temp_expected, "w");
                    if (fd_exp) { fd_exp.write(expected_output); fd_exp.close(); }
                    let fd_act = fs.open(temp_actual, "w");
                    if (fd_act) { fd_act.write(output); fd_act.close(); }
                    
                    // Show diff
                    let diff_cmd = sprintf("diff -u %s %s", temp_expected, temp_actual);
                    let diff_output = fs.popen(diff_cmd);
                    if (diff_output) {
                        let diff_result = diff_output.read("all");
                        diff_output.close();
                        printf("Diff:\n%s\n", diff_result);
                    }
                    
                    this.test_results.failed++;
                }
            } catch (e) {
                printf("✗ ERROR: %s (%s) - %s\n", test_name, board_name, e);
                if (e.stacktrace && e.stacktrace[0]?.context) {
                    printf("  Error: %s\n", e.stacktrace[0].context);
                }
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
            
            printf("=== Test Results ===\n");
            printf("Passed: %d\n", this.test_results.passed);
            printf("Failed: %d\n", this.test_results.failed);
            
            if (this.test_results.failed == 0) {
                printf("All %s tests passed!\n", this.test_title);
            }
            
            return {
                passed: this.test_results.passed,
                failed: this.test_results.failed,
                errors: this.test_results.errors,
                suite_name: this.test_title
            };
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
                // Load expected output for comparison
                let output_path = sprintf("%s/output/%s/%s", this.test_dir, board_name, expected_file);
                let expected_output = fs.readfile(output_path);

                if (expected_output === null || expected_output === false) {
                    expected_output = "";
                }

                // Use separate process to avoid file descriptor leaks
                // Combine stdout and stderr to see all output including errors
                let cmd = sprintf("ucode helpers/run-single-integration-test.uc '%s' '%s' '%s' '%s' 2>&1",
                                this.test_dir, input_file, board_name, expected_file);

                let proc = fs.popen(cmd);
                if (!proc) {
                    printf("✗ ERROR: %s (%s) - Failed to start test process\n", test_name, board_name);
                    this.test_results.failed++;
                    return;
                }

                let actual_output = proc.read("all");
                let exit_code = proc.close();

                if (exit_code !== 0) {
                    printf("✗ ERROR: %s (%s) - Process failed with code %d\n", test_name, board_name, exit_code);
                    printf("Process output:\n%s\n", actual_output);
                    this.test_results.failed++;
                    return;
                }

                // Compare output
                actual_output = trim(actual_output);
                expected_output = trim(expected_output);

                if (actual_output == expected_output) {
                    printf("✓ PASS: %s (%s)\n", test_name, board_name);
                    this.test_results.passed++;
                } else {
                    printf("✗ FAIL: %s (%s)\n", test_name, board_name);
                    // Create diff files
                    try { fs.mkdir("/tmp/ucentral-test-diff"); } catch (e) {}

                    let temp_expected = "/tmp/ucentral-test-diff/expected_" + test_name + "-" + board_name + ".uci";
                    let temp_actual = "/tmp/ucentral-test-diff/actual_" + test_name + "-" + board_name + ".uci";
                    let fd_exp = fs.open(temp_expected, "w");
                    if (fd_exp) { fd_exp.write(expected_output); fd_exp.close(); }
                    let fd_act = fs.open(temp_actual, "w");
                    if (fd_act) { fd_act.write(actual_output); fd_act.close(); }

                    this.test_results.failed++;
                }

            } catch (e) {
                printf("✗ ERROR: %s (%s) - %s\n", test_name, board_name, e);
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
            
            printf("=== Test Results ===\n");
            printf("Passed: %d\n", this.test_results.passed);
            printf("Failed: %d\n", this.test_results.failed);
            
            if (this.test_results.failed == 0) {
                printf("All %s tests passed!\n", this.test_title);
            }
            
            return {
                passed: this.test_results.passed,
                failed: this.test_results.failed,
                errors: this.test_results.errors,
                suite_name: this.test_title
            };
        }
    };
};
