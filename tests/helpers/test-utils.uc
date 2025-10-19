// Shared test utility functions for ucentral-schema test framework
// Consolidates common patterns and eliminates duplication

"use strict";

import * as fs from 'fs';
import {
	b, s, uci_cmd, uci_set_string, uci_set_boolean, uci_set_number, uci_set_raw,
	uci_list_string, uci_list_number, uci_section, uci_named_section,
	uci_set, uci_list, uci_output, uci_comment
} from '../../renderer/libs/uci_helpers.uc';
import { create_ethernet } from '../../renderer/libs/ethernet.uc';
import { create_wiphy } from '../../renderer/libs/wiphy.uc';
import { create_routing_table } from '../../renderer/libs/routing_table.uc';
import { create_captive } from '../../renderer/libs/captive.uc';

// Real filesystem access for reading actual board configuration files
let fs_real = require("fs");

// Mock toplevel initialization logic
// Initializes interface arrays and sets up VLAN properties like toplevel.uc
export function mock_toplevel(state) {
	// Initialize interfaces array if it doesn't exist
	if (!state.interfaces) {
		state.interfaces = [];
	}

	// Initialize VLAN properties like toplevel.uc does
	for (let i, interface in state.interfaces) {
		interface.index = i; // Set interface index

		// Note: We'll rely on the real ethernet mock for VLAN logic
		if (!interface.vlan) {
			interface.vlan = { id: 0 }; // Default VLAN like toplevel.uc
		}
	}
};

// Read board-specific files with standardized error handling
// Handles path resolution and provides consistent error messages
export function read_board_file(path, file_type) {
	let real_path = path;

	// If path doesn't start with tests/, prepend it
	if (!match(path, /^tests\//)) {
		real_path = "tests/" + path;
	}

	try {
		return fs_real.readfile(real_path);
	} catch (e) {
		die(sprintf("Failed to read %s file: %s (%s)", file_type, real_path, e));
	}
};

// Check if a path refers to a specific file type
export function is_capabilities_file(path) {
	return index(path, "capabilities.json") >= 0;
};

export function is_board_file(path) {
	return index(path, "board.json") >= 0;
};

export function is_qos_file(path) {
	return index(path, "qos.json") >= 0 || index(path, "/usr/share/ucentral/qos.json") >= 0;
};

// Load board capabilities with error handling
export function load_board_capabilities(board_name) {
	board_name ??= 'eap101';
	try {
		return json(fs.readfile(sprintf("boards/%s/capabilities.json", board_name)));
	} catch (e) {
		die(sprintf("Failed to load capabilities for board %s: %s", board_name, e));
	}
};

// Load board data with error handling
export function load_board_data(board_name) {
	board_name ??= 'eap101';
	try {
		return json(fs_real.readfile(sprintf("boards/%s/board.json", board_name)));
	} catch (e) {
		die(sprintf("Failed to load board data for %s: %s", board_name, e));
	}
};

// Load wiphy data with error handling
export function load_wiphy_data(board_name) {
	board_name ??= 'eap101';
	try {
		let wiphy_path = sprintf("boards/%s/wiphy.json", board_name);
		let wiphy_content = fs_real.readfile(wiphy_path);
		return json(wiphy_content);
	} catch (e) {
		die(sprintf("Failed to read wiphy data for %s: %s", board_name, e));
	}
};

// Base context initialization - creates shared objects for all context types
// This eliminates the duplication in ethernet, wiphy, routing_table, captive setup
export function create_base_context_objects(board_name, capabilities, mock_cursor_factory, mock_fs) {
	board_name ??= 'eap101';

	// Initialize shared objects (pattern used in all 4 context creation functions)
	let mock_ethernet = create_ethernet(capabilities, mock_fs, null);
	let cursor = mock_cursor_factory(board_name);

	// Initialize wiphy with board-specific wiphy data
	let mock_wiphy = create_wiphy(cursor, function(fmt, ...args) {
		printf("[W] " + sprintf(fmt, ...args) + "\n");
	});

	// Load wiphy data using shared utility
	mock_wiphy.phys = load_wiphy_data(board_name);

	// Initialize routing table and captive portal manager
	let mock_routing_table = create_routing_table();
	let mock_captive = create_captive();

	return {
		cursor,
		ethernet: mock_ethernet,
		wiphy: mock_wiphy,
		routing_table: mock_routing_table,
		captive: mock_captive
	};
};

// Standard context properties shared by all context types
// This eliminates the duplication of UCI helpers and utility functions
export function create_standard_context_properties() {
	return {
		// Basic functions
		b, s,

		// UCI helpers
		uci_cmd,
		uci_set_string,
		uci_set_boolean,
		uci_set_number,
		uci_set_raw,
		uci_list_string,
		uci_list_number,
		uci_section,
		uci_named_section,
		uci_set,
		uci_list,
		uci_output,
		uci_comment,

		// Mock utility functions
		warn: function(fmt, ...args) {
			printf("[W] " + sprintf(fmt, ...args) + "\n");
		},
		error: function(fmt, ...args) {
			printf("[E] " + sprintf(fmt, ...args) + "\n");
		},
		info: function(fmt, ...args) {
			printf("[I] " + sprintf(fmt, ...args) + "\n");
		}
	};
};

// Apply overrides logic for test contexts
// Centralizes the override merging logic used in create_test_context
export function apply_context_overrides(result, overrides, services_mock) {
	if (!overrides)
		return result;

	// Manually merge overrides
	for (let key, value in overrides) {
		// Don't override the services mock object
		if (key != 'services') {
			result[key] = value;
		}
	}

	// Extract individual services from services object
	if (overrides.services) {
		for (let service_name, service_config in overrides.services) {
			result[service_name] = service_config;
		}
	}

	// Extract individual metrics from metrics object
	if (overrides.metrics) {
		for (let metric_name, metric_config in overrides.metrics) {
			result[metric_name] = metric_config;
		}
	}

	// Set test state in services mock for lookup_interfaces
	if (overrides.state) {
		services_mock._test_state = overrides.state;
	} else {
		services_mock._test_state = overrides;
	}

	return result;
};

// Shared test execution utilities - eliminates duplication across test framework classes

// Test result reporting functions - standardizes output formatting
export function report_test_pass(test_name, board_name) {
	if (board_name) {
		printf("✓ PASS: %s (%s)\n", test_name, board_name);
	} else {
		printf("✓ PASS: %s\n", test_name);
	}
};

export function report_test_fail(test_name, board_name) {
	if (board_name) {
		printf("✗ FAIL: %s (%s)\n", test_name, board_name);
	} else {
		printf("✗ FAIL: %s\n", test_name);
	}
};

export function report_test_error(test_name, board_name, error) {
	if (board_name) {
		printf("✗ ERROR: %s (%s) - %s\n", test_name, board_name, error);
	} else {
		printf("✗ ERROR: %s - %s\n", test_name, error);
	}

	// Show error context if available
	if (error.stacktrace && error.stacktrace[0]?.context) {
		printf("  Error: %s\n", error.stacktrace[0].context);
	}
};

// Diff generation utilities - eliminates duplication in failure handling
export function create_diff_files(test_name, board_name, expected_output, actual_output) {
	// Create diff directory
	try {
		fs.mkdir("/tmp/ucentral-test-diff");
	} catch (e) {}

	// Generate unique filenames
	let suffix = board_name ? test_name + "-" + board_name : test_name;
	let temp_expected = "/tmp/ucentral-test-diff/expected_" + suffix + ".uci";
	let temp_actual = "/tmp/ucentral-test-diff/actual_" + suffix + ".uci";

	// Write files
	let fd_exp = fs.open(temp_expected, "w");
	if (fd_exp) {
		fd_exp.write(expected_output);
		fd_exp.close();
	}

	let fd_act = fs.open(temp_actual, "w");
	if (fd_act) {
		fd_act.write(actual_output);
		fd_act.close();
	}

	// Show diff
	let diff_cmd = sprintf("diff -u %s %s", temp_expected, temp_actual);
	let diff_output = fs.popen(diff_cmd);
	if (diff_output) {
		let diff_result = diff_output.read("all");
		diff_output.close();
		printf("Diff:\n%s\n", diff_result);
	}
};

// File handling utilities - standardizes test file operations
export function load_test_files(test_dir, input_file, expected_file, board_name) {
	// Load input file
	let input_path = sprintf("%s/%s", test_dir, input_file);
	let test_data = json(fs_real.readfile(input_path));

	// Load expected output file
	let output_path = expected_file;
	if (board_name) {
		output_path = sprintf("%s/output/%s/%s", test_dir, board_name, expected_file);
	} else {
		output_path = sprintf("%s/%s", test_dir, expected_file);
	}

	let expected_output = fs_real.readfile(output_path);
	if (expected_output === null || expected_output === false) {
		expected_output = "";
	}

	return {
		test_data,
		expected_output
	};
};

// Board data loading utilities - eliminates duplication in integration tests
export function load_test_board_data(board_name) {
	let board_dir = sprintf("boards/%s", board_name);
	let board_data = json(fs_real.readfile(sprintf("%s/board.json", board_dir)));
	let capabilities = json(fs_real.readfile(sprintf("%s/capabilities.json", board_dir)));

	return {
		board_data,
		capabilities
	};
};

// Test output processing - standardizes template rendering and file generation
export function process_test_output(context, template_path, test_name, test_dir, board_name) {
	// Clear any previous generated files
	context.files.clear_generated_files();

	// Render template
	let abs_path = fs_real.realpath ? fs_real.realpath(template_path) : template_path;
	let output = render(abs_path, context);

	// Add generated files to output
	let generated_files = context.files.get_generated_files();
	for (let path, file_info in generated_files) {
		output += sprintf("\n-----%s-----\n%s\n--------\n", path, file_info.content);
	}

	// Write debug output
	let debug_path = board_name ? test_name + "-" + board_name : test_name;
	context.files.write_debug_output(test_dir + "/" + debug_path, output);

	return trim(output);
};

// Test suite result formatting - eliminates duplication in result reporting
export function format_test_suite_results(test_results, suite_name) {
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
	} else {
		printf("All %s tests passed!\n", suite_name);
	}

	// Return results for aggregation
	return {
		passed: test_results.passed,
		failed: test_results.failed,
		errors: test_results.errors,
		suite_name: suite_name
	};
};