// Shared test utility functions for ucentral-schema test framework
// Consolidates common patterns and eliminates duplication

"use strict";

import * as fs from 'fs';

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