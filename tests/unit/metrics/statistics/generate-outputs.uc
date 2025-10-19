#!/usr/bin/env ucode

// Generate expected outputs for statistics metrics template tests

"use strict";

import * as fs from 'fs';
import { create_test_context } from '../../../helpers/mock-renderer.uc';

let test_cases = [
    'statistics-no-config',
    'statistics-basic', 
    'statistics-all-types',
    'statistics-custom-interval',
    'statistics-empty-types'
];

for (let test_case in test_cases) {
    let input_file = `input/${test_case}.json`;
    let output_file = `output/${test_case}.uci`;
    
    printf("Generating output for: %s\n", test_case);
    
    let input_data = json(fs.readfile(input_file));
    let context = create_test_context(input_data);
    
    // Clear any previous generated files
    context.files.clear_generated_files();
    
    // Render template
    let output = render("../../../../renderer/templates/metric/statistics.uc", context);
    
    // Add generated files to output
    let generated_files = context.files.get_generated_files();
    for (let path, file_info in generated_files) {
        output += sprintf("\n-----%s-----\n%s\n--------\n", path, file_info.content);
    }
    
    fs.writefile(output_file, output);
    printf("Generated: %s\n", output_file);
}

printf("All outputs generated.\n");