#!/usr/bin/env ucode

import * as fs from 'fs';
import { create_test_context } from '../../../helpers/mock-renderer.uc';

let test_data = json(fs.readfile("input/qos-services.json"));
let context = create_test_context(test_data);

printf("QoS config: %J\n", context.quality_of_service);
printf("Services list: %J\n", context.quality_of_service.services);

// Test qos.json loading directly
let fs_real = require("fs");
let qos_content = fs_real.readfile("../../../../renderer/qos.json");
printf("QoS JSON loaded: %s\n", qos_content ? "YES" : "NO");

// Try to render just part of the template  
try {
	let output = render("../../../../renderer/templates/services/quality_of_service.uc", context);
	printf("Template rendered successfully\n");
} catch (e) {
	printf("Template error: %s\n", e);
	printf("Stack: %s\n", e.stacktrace);
}