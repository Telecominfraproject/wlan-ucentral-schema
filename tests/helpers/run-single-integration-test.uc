#!/usr/bin/env ucode
// Single integration test runner to avoid file descriptor leaks

"use strict";

import { validate } from './schemareader.uc';
import { create_full_test_context } from './mock-renderer.uc';
import { mock_toplevel } from './test-utils.uc';

// Get command line arguments
let args = ARGV;
if (length(args) < 4) {
    printf("Usage: run-single-integration-test.uc <test_dir> <input_file> <board_name> <expected_file>\n");
    exit(1);
}

let test_dir = args[0];
let input_file = args[1];
let board_name = args[2];
let expected_file = args[3];

try {
    // Load complete configuration
    let fs = require("fs");
    let input_path = sprintf("%s/%s", test_dir, input_file);
    let config_json = json(fs.readfile(input_path));

    // Load board data
    let board_dir = sprintf("boards/%s", board_name);
    let board_data = json(fs.readfile(sprintf("%s/board.json", board_dir)));
    let capabilities = json(fs.readfile(sprintf("%s/capabilities.json", board_dir)));

    // Validate configuration
    let logs = [];
    let state = validate(config_json, logs);
    if (!state) {
        printf("VALIDATION_FAILED: %s\n", join("\n", logs));
        exit(1);
    }

    // Initialize state
    mock_toplevel(state);

    // Create context and render
    let context = create_full_test_context(state, board_data, capabilities, board_name);

    let abs_path = fs.realpath("../renderer/templates/toplevel.uc");
    let output = render(abs_path, context);

    // Add generated files
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