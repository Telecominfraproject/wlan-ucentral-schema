#!/usr/bin/env ucode
// Generic single test runner to avoid file descriptor leaks
// Supports both unit tests and integration tests

"use strict";

import { validate } from './schemareader.uc';
import { create_test_context, create_full_test_context } from './mock-renderer.uc';
import { mock_toplevel, load_test_board_data } from './test-utils.uc';

// Get command line arguments
let args = ARGV;
if (length(args) < 4) {
    printf("Usage: run-single-test.uc <test_type> <template_path> <test_dir> <input_file> [board_name] [expected_file]\n");
    printf("  test_type: 'unit' or 'integration'\n");
    printf("  For unit tests: run-single-test.uc unit template.uc test_dir input.json\n");
    printf("  For integration tests: run-single-test.uc integration toplevel.uc test_dir input.json board_name expected.uci\n");
    exit(1);
}

let test_type = args[0];
let template_path = args[1];
let test_dir = args[2];
let input_file = args[3];
let board_name = args[4]; // Optional for unit tests
let expected_file = args[5]; // Optional for unit tests

// Validate test type
if (test_type != "unit" && test_type != "integration") {
    printf("ERROR: test_type must be 'unit' or 'integration', got '%s'\n", test_type);
    exit(1);
}

try {
    // Load test configuration
    let fs = require("fs");
    let input_path = sprintf("%s/%s", test_dir, input_file);
    let config_json = json(fs.readfile(input_path));

    let context;
    let state;

    if (test_type == "integration") {
        // Integration test path - requires validation and board data
        if (!board_name) {
            printf("ERROR: board_name is required for integration tests\n");
            exit(1);
        }

        // Load board data
        let board_info = load_test_board_data(board_name);
        let board_data = board_info.board_data;
        let capabilities = board_info.capabilities;

        // Validate configuration
        let logs = [];
        state = validate(config_json, logs);
        if (!state) {
            printf("VALIDATION_FAILED: %s\n", join("\n", logs));
            exit(1);
        }

        // Initialize state like toplevel.uc does
        mock_toplevel(state);

        // Create full test context for integration tests
        context = create_full_test_context(state, board_data, capabilities, board_name);

        // Use toplevel.uc template for integration tests
        template_path = "../renderer/templates/toplevel.uc";

    } else {
        // Unit test path - uses test data directly with overrides
        state = config_json;

        // Initialize state like toplevel.uc does
        mock_toplevel(state);

        // Create test context with overrides for unit tests
        context = create_test_context(state);

        // Add template vars to context
        for (let key, value in state.template_vars || {}) {
            context[key] = value;
        }

        // Use specified template path for unit tests
        template_path = "../" + template_path;
    }

    // Render template
    let abs_path = fs.realpath(template_path);
    let output = render(abs_path, context);

    // Add generated files to output
    let generated_files = context.files.get_generated_files();
    for (let path, file_info in generated_files) {
        output += sprintf("\n-----%s-----\n%s\n--------\n", path, file_info.content);
    }

    // Output result
    printf("%s", output);
    exit(0);

} catch (e) {
    printf("ERROR: %s\n", e);
    if (e.stacktrace && e.stacktrace[0]?.context) {
        printf("  Error context: %s\n", e.stacktrace[0].context);
    }
    if (e.stacktrace) {
        printf("  Stacktrace:\n");
        for (let frame in e.stacktrace) {
            printf("    %s\n", frame.context || frame);
        }
    }
    exit(1);
}