#!/usr/bin/env ucode

// Generate expected outputs for RADIUS Proxy tests

"use strict";

import * as fs from 'fs';
import { create_test_context } from '../../../helpers/mock-renderer.uc';

function generate_output(test_name, input_file, output_file) {
	printf("Generating output: %s\n", test_name);
	
	try {
		// Load test data
		let test_data = json(fs.readfile(input_file));
		
		// Create test context
		let context = create_test_context(test_data);
		
		// Add template vars to context
		for (let key, value in test_data.template_vars || {}) {
			context[key] = value;
		}
		
		// Clear any previous generated files
		context.files.clear_generated_files();
		
		// Render template
		let output = render("../../../../renderer/templates/services/radius_proxy.uc", context);
		
		// Add generated files to output
		let generated_files = context.files.get_generated_files();
		for (let path, file_info in generated_files) {
			output += sprintf("\n-----%s-----\n%s\n--------\n", path, file_info.content);
		}
		
		// Write expected output to file
		fs.writefile(output_file, output);
		printf("✓ Generated: %s\n", output_file);
		
	} catch (e) {
		printf("✗ ERROR generating %s: %s\n", test_name, e);
	}
}

function main() {
	printf("=== Generating RADIUS Proxy Test Outputs ===\n\n");
	
	// Generate all expected outputs
	generate_output("radius-proxy-radsec", "input/radius-proxy-radsec.json", "output/radius-proxy-radsec.uci");
	generate_output("radius-proxy-radius", "input/radius-proxy-radius.json", "output/radius-proxy-radius.uci");
	generate_output("radius-proxy-block", "input/radius-proxy-block.json", "output/radius-proxy-block.uci");
	generate_output("radius-proxy-mixed", "input/radius-proxy-mixed.json", "output/radius-proxy-mixed.uci");
	generate_output("radius-proxy-disabled", "input/radius-proxy-disabled.json", "output/radius-proxy-disabled.uci");
	
	printf("\nAll expected outputs generated!\n");
}

main();