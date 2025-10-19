// Mock renderer environment for testing templates

"use strict";

import * as fs from 'fs';
import {
	read_board_file, is_capabilities_file, is_board_file, is_qos_file,
	load_board_capabilities, load_wiphy_data, create_base_context_objects,
	create_standard_context_properties, apply_context_overrides, build_context
} from './test-utils.uc';

import { 
	b, s, uci_cmd, uci_set_string, uci_set_boolean, uci_set_number, uci_set_raw,
	uci_list_string, uci_list_number, uci_section, uci_named_section, 
	uci_set, uci_list, uci_output, uci_comment
} from '../../renderer/libs/uci_helpers.uc';
import { create_ethernet } from '../../renderer/libs/ethernet.uc';
import { create_wiphy } from '../../renderer/libs/wiphy.uc';
import { create_routing_table } from '../../renderer/libs/routing_table.uc';
import { create_captive } from '../../renderer/libs/captive.uc';

// Create mock cursor factory that uses board-specific data
function create_mock_cursor(board) {
	board ??= 'eap101';

	return {
		_wifi_devices: null, // Will be loaded from wifi_devices.json
		_board: board,

		load: function(config) {
			// Load real wifi device data when wireless config is requested
			if (config == "wireless" && !this._wifi_devices) {
				try {
						let wifi_devices_content = fs.readfile(sprintf("boards/%s/wifi_devices.json", this._board));
					let wifi_data = json(wifi_devices_content);
					this._wifi_devices = wifi_data.devices || [];
				} catch (e) {
					die(sprintf("Failed to read wifi devices data for board %s: %s", this._board, e));
				}
			}
		},

		foreach: function(config, type, callback) {
			if (config == "wireless" && type == "wifi-device") {
				// Ensure wifi devices are loaded
				this.load("wireless");
				// Call callback for each wifi device
				for (let device in this._wifi_devices) {
					let result = callback(device);
					// If callback returns false, stop iteration
					if (result === false)
						break;
				}
			}
		},

		get_all: function(config, section) {
			// Return mock system data
			if (config == "system" && section == "@system[-1]") {
				return { hostname: "mock-hostname" };
			}
			if (config == "system" && section == "@certificates[-1]") {
				return {
					ca: "/etc/ssl/ca.pem",
					cert: "/etc/ssl/cert.pem",
					key: "/etc/ssl/key.pem"
				};
			}
			return {};
		},
		get: function(config, section, option) {
			if (config == "ucentral" && section == "config" && option == "serial")
				return "mock-serial-123";
			return null;
		}
	};
}

// Mock ubus connection
let mock_conn = {
	call: function(service, method, args) {
		// Mock ubus calls
		return {};
	}
};

// Mock filesystem operations
let mock_fs = {
	open: function(path, mode) {
		// Mock file operations
		return {
			read: function(size) {
				if (is_capabilities_file(path)) {
					return read_board_file(path, "capabilities");
				}
				if (is_board_file(path)) {
					return read_board_file(path, "board");
				}
				if (is_qos_file(path)) {
					// Read the actual qos.json file
					return fs.readfile("../../../../renderer/qos.json");
				}
				return "";
			},
			write: function(data) {},
			close: function() {}
		};
	},
	readfile: function(path) {
		if (is_capabilities_file(path)) {
			return read_board_file(path, "capabilities");
		}
		if (is_board_file(path)) {
			return read_board_file(path, "board");
		}
		return null;
	},
	stat: function(path) {
		// Mock file stats - assume files exist
		return { type: 'regular' };
	},
	mkdir: function(path) {
		// Mock directory creation - always succeed
		// For templates that need to create /tmp/ucentral/, redirect to test directory
		if (path == '/tmp/ucentral' || path == '/tmp/ucentral/') {
			// Use real fs to create test directory
			try {
				fs.mkdir('/tmp/ucentral-test');
			} catch (e) {
				// Directory might already exist
			}
			return true;
		}
		// For other paths, just pretend it worked
		return true;
	},
	glob: function(pattern) {
		// Mock glob results
		return [];
	},
	popen: function(cmd) {
		return {
			read: function() { return "developer=0\n"; },
			close: function() {}
		};
	}
};

// Load capabilities from board data
function mock_capab(board) {
	return load_board_capabilities(board);
}


// Mock restrictions (empty for developer mode)
let mock_restrict = {};

// Mock default config
let mock_default_config = {
	country: "US"
};

// Mock events data for event-based templates (realtime, telemetry)
let mock_events = {
    "client.associate": true,
    "client.disassociate": true,
    "wifi.start": true,
    "wifi.stop": true,
    "dhcp.ack": true,
    "dhcp.discover": true,
    "dns.query": true
};


// Mock services object
let mock_services = {
	state: {},
	set_enabled: function(name, state) {
		this.state[name] = state;
	},
	is_present: function(name) {
		return true; // Assume all services are present
	},
	lookup_interfaces: function(service) {
		// Return interfaces that have the requested service
		let interfaces = [];
		if (this._test_state && this._test_state.interfaces) {
			for (let iface in this._test_state.interfaces) {
				if (iface.services && index(iface.services, service) >= 0) {
					push(interfaces, iface);
				}
			}
		}
		return interfaces;
	},
	lookup_ssids: function(service) {
		// Return SSIDs that have the requested service
		let ssids = [];
		if (this._test_state && this._test_state.interfaces) {
			for (let iface in this._test_state.interfaces) {
				if (iface.ssids) {
					for (let ssid in iface.ssids) {
						if (ssid.services && index(ssid.services, service) >= 0) {
							push(ssids, ssid);
						}
					}
				}
			}
		}
		return ssids;
	},
	lookup_interfaces_by_ssids: function(service) {
		// Return interfaces that have SSIDs requesting the specified service
		let interfaces = [];
		if (this._test_state && this._test_state.interfaces) {
			for (let iface in this._test_state.interfaces) {
				if (iface.ssids) {
					for (let ssid in iface.ssids) {
						if (ssid.services && index(ssid.services, service) >= 0) {
							push(interfaces, iface);
							break; // Don't add the same interface multiple times
						}
					}
				}
			}
		}
		return interfaces;
	},
	lookup_services: function() {
		// Dynamic service discovery like the real renderer
		let rv = [];

		for (let incfile in fs.glob("../renderer/templates/services/*.uc")) {
			let m = match(incfile, /^.+\/([^\/]+)\.uc$/);
			if (m)
				push(rv, m[1]);
		}

		return rv;
	},
	lookup_metrics: function() {
		// Dynamic metrics discovery like the real renderer
		let rv = [];

		for (let incfile in fs.glob("../renderer/templates/metric/*.uc")) {
			let m = match(incfile, /^.+\/([^\/]+)\.uc$/);
			if (m)
				push(rv, m[1]);
		}

		return rv;
	},
	lookup_ssids_by_mpsk: function() {
		// Check for SSIDs with MPSK configuration (like the real implementation)
		let mpsk = false;

		if (this._test_state && this._test_state.interfaces) {
			for (let interface in this._test_state.interfaces) {
				if (!interface.ssids)
					continue;
				for (let ssid in interface.ssids) {
					if (!ssid?.enhanced_mpsk)
						continue;
					if ((ssid?.encryption?.proto && type(ssid.encryption.proto) == 'string' &&
					    ssid.encryption.proto == "mpsk-radius") ||
					    (type(ssid.multi_psk) == 'bool' && ssid.multi_psk))
						mpsk = true;
					else if (!length(ssid.multi_psk))
						continue;
					mpsk = true;
				}
			}
		}

		return mpsk;
	},
	_test_state: null // Will be set by test context
};


// Mock files object
let mock_files = {
	_generated_files: {},
	_test_dir: "/tmp/ucentral-test",
	
	add_named: function(path, content) {
		// Create test directory structure
		let test_path = this._test_dir + path;
		let dir_path = replace(test_path, /\/[^\/]+$/, '');
		
		// Ensure directory exists using fs.mkdir
		try {
			// Create directory recursively
			let path_parts = split(dir_path, '/');
			let current_path = '';
			for (let part in path_parts) {
				if (part == '')
					continue;
				current_path += '/' + part;
				try {
					fs.mkdir(current_path);
				} catch (e) {
					// Directory might already exist, ignore error
				}
			}
		} catch (e) {
			// Ignore mkdir errors
		}
		
		// Write file content
		let fd = fs.open(test_path, "w");
		if (fd) {
			fd.write(content);
			fd.close();
		}
		
		// Track file for test validation
		this._generated_files[path] = {
			test_path: test_path,
			content: content
		};
	},
	
	add_anonymous: function(location, name, content) {
		let path = "/tmp/mock/" + name;
		this.add_named(path, content);
		return path;
	},
	
	get_generated_files: function() {
		return this._generated_files;
	},
	
	get_file_content: function(path) {
		if (this._generated_files[path]) {
			return this._generated_files[path].content;
		}
		return null;
	},
	
	clear_generated_files: function() {
		this._generated_files = {};
		// Remove entire test directory
		try {
			fs.unlink(this._test_dir);
		} catch (e) {
			// Directory might not exist, ignore error
		}
	},
	
	write_debug_output: function(test_path, output) {
		// Write test output to /tmp/ucentral-test-output/ for debugging
		let debug_dir = "/tmp/ucentral-test-output";

		// Create subdirectories to mirror test structure
		// e.g. "unit/services/dhcp_snooping/dhcp-snooping-basic" -> "/tmp/ucentral-test-output/unit/services/dhcp_snooping/dhcp-snooping-basic.uci"
		let path_parts = split(test_path, "/");
		let test_name = path_parts[-1]; // Last part is the test name
		let dir_parts = slice(path_parts, 0, -1); // All parts except the last

		let full_dir = debug_dir;
		for (let part in dir_parts) {
			full_dir += "/" + part;
			try {
				fs.mkdir(full_dir);
			} catch (e) {
				// Directory might already exist
			}
		}

		let debug_file = full_dir + "/" + test_name + ".uci";
		let fd = fs.open(debug_file, "w");
		if (fd) {
			fd.write(output);
			fd.close();
			printf("Debug output written to: %s\n", debug_file);
		}
	}
};

// Mock shell object for password management
let mock_shell = {
	system_password: function(password) {
		// Mock implementation - in real system this would set system password
		return 0;
	},
	password: function(password) {
		// Mock implementation - in real system this would set random password
		return 0;
	}
};

// Mock latency object
let mock_latency = {
	// Mock latency measurement functions
	write: function() {
		// Mock implementation - do nothing
	}
};

// Mock local_profile object
let mock_local_profile = {
	get: function() {
		// Mock implementation - return null since most tests don't need profile data
		return null;
	}
};

// tryinclude function from renderer.uc
function tryinclude(path, scope) {
	if (!match(path, /^[A-Za-z0-9_\/-]+\.uc$/)) {
		warn("Refusing to handle invalid include path '%s'", path);
		return;
	}
	let parent_path = sourcepath(1, true);
	assert(parent_path, "Unable to determine calling template path");
	try {
		include(parent_path + "/" + path, scope);
	}
	catch (e) {
		warn("Unable to include path '%s': %s\n%s", path, e, e.stacktrace[0].context);
	}
};

// Create ethernet instance using shared library (initialized in test context)
let mock_ethernet;

// Create wiphy instance using shared library (initialized in test context)
let mock_wiphy;

// Create routing table instance using shared library
let mock_routing_table;

// Create captive instance using shared library
let mock_captive;


// Create test context with all mocks
function create_test_context(overrides) {
	// Initialize with board capabilities (unit tests use eap101 by default)
	let board = 'eap101';
	let capabilities = mock_capab(board);

	// Create base context objects using shared utility
	let base_objects = create_base_context_objects(board, capabilities, create_mock_cursor, mock_fs);

	// Reset mock files state for clean test runs
	mock_files.clear_generated_files();

	// Build result using standardized context builder
	let result = build_context({
		cursor: base_objects.cursor,
		conn: mock_conn,
		fs: mock_fs,
		capab: capabilities,
		restrict: mock_restrict,
		default_config: mock_default_config,
		services: mock_services,
		ethernet: base_objects.ethernet,
		wiphy: base_objects.wiphy,
		routing_table: base_objects.routing_table,
		captive: base_objects.captive,
		files: mock_files,
		events: mock_events,
		shell: mock_shell
	});

	// Apply overrides using shared utility
	result = apply_context_overrides(result, overrides, mock_services);

	// Set global state for ethernet library functions
	global.state = overrides || {};

	return result;
}

// Create board-specific test context with real device data
function create_board_test_context(test_data, board_data, capabilities, board_name) {
	// Use the board name passed from the test framework, default to eap101
	board_name ??= 'eap101';

	// Create board-specific context objects using shared utility
	let base_objects = create_base_context_objects(board_name, capabilities, create_mock_cursor, mock_fs);

	// Reset mock files state for clean test runs
	mock_files.clear_generated_files();

	// Get base context for test data with overrides
	let base_context = create_test_context(test_data);

	// Build result using standardized context builder (declarative approach)
	return build_context({
		...base_context,
		cursor: base_objects.cursor,
		capab: capabilities,
		ethernet: base_objects.ethernet,
		wiphy: base_objects.wiphy,
		routing_table: base_objects.routing_table,
		captive: base_objects.captive,
		board: board_data
	});
};

// Create integration test context without override logic
function create_integration_test_context(board_data, capabilities, board_name) {
	// Use the board name passed from the test framework, default to eap101
	board_name ??= 'eap101';

	// Create board-specific context objects using shared utility
	let base_objects = create_base_context_objects(board_name, capabilities, create_mock_cursor, mock_fs);

	// Reset mock files state for clean test runs
	mock_files.clear_generated_files();

	// Initialize with board capabilities (no overrides logic)
	let capabilities_for_context = mock_capab(board_name);

	// Build result using standardized context builder (declarative approach)
	let result = build_context({
		cursor: base_objects.cursor,
		conn: mock_conn,
		fs: mock_fs,
		capab: capabilities_for_context,
		restrict: mock_restrict,
		default_config: mock_default_config,
		services: mock_services,
		ethernet: base_objects.ethernet,
		wiphy: base_objects.wiphy,
		routing_table: base_objects.routing_table,
		captive: base_objects.captive,
		files: mock_files,
		events: mock_events,
		shell: mock_shell
	});

	// Don't set any override state for integration tests - services will be passed via context.state

	// Set global state for ethernet library functions
	global.state = {}; // Will be set later with actual state

	return result;
}

// Create full test context for toplevel.uc rendering
function create_full_test_context(state, board_data, capabilities, board_name) {
	// For integration tests, don't use the override logic - create clean context
	let base_context = create_integration_test_context(board_data, capabilities, board_name);

	// Set the test state for services mock to use the actual validated state
	base_context.services._test_state = state;

	// Set global state for ethernet library functions
	global.state = state;

	// Build result using standardized context builder (declarative approach)
	return build_context({
		...base_context,
		state: state,
		location: '/',
		capab: capabilities,
		restrict: {},
		default_config: mock_default_config,
		latency: mock_latency,
		local_profile: mock_local_profile,
		tryinclude: tryinclude
	});
};

// Export the functions
export { create_test_context, create_board_test_context, create_full_test_context };
