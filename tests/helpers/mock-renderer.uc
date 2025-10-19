// Mock renderer environment for testing templates

"use strict";

import * as fs from 'fs';

// Real filesystem access for reading actual board configuration files
let fs_real = require("fs");
import { 
	b, s, uci_cmd, uci_set_string, uci_set_boolean, uci_set_number, uci_set_raw,
	uci_list_string, uci_list_number, uci_section, uci_named_section, 
	uci_set, uci_list, uci_output, uci_comment
} from '../../renderer/libs/uci_helpers.uc';
import { create_ethernet } from '../../renderer/libs/ethernet.uc';
import { create_wiphy } from '../../renderer/libs/wiphy.uc';
import { create_routing_table } from '../../renderer/libs/routing_table.uc';

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
						let wifi_devices_content = fs_real.readfile(sprintf("boards/%s/wifi_devices.json", this._board));
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
				if (index(path, "capabilities.json") >= 0) {
					// Read actual capabilities file from tests/boards/
					let real_path = path;
					// If path doesn't start with tests/, prepend it
					if (!match(path, /^tests\//)) {
						real_path = "tests/" + path;
					}
					try {
						return fs_real.readfile(real_path);
					} catch (e) {
						die(sprintf("Failed to read capabilities file: %s (%s)", real_path, e));
					}
				}
				if (index(path, "board.json") >= 0) {
					// Read actual board file from tests/boards/
					let real_path = path;
					// If path doesn't start with tests/, prepend it
					if (!match(path, /^tests\//)) {
						real_path = "tests/" + path;
					}
					try {
						return fs_real.readfile(real_path);
					} catch (e) {
						die(sprintf("Failed to read board file: %s (%s)", real_path, e));
					}
				}
				if (index(path, "qos.json") >= 0 || index(path, "/usr/share/ucentral/qos.json") >= 0) {
					// Read the actual qos.json file
					return fs_real.readfile("../../../../renderer/qos.json");
				}
				return "";
			},
			write: function(data) {},
			close: function() {}
		};
	},
	readfile: function(path) {
		if (index(path, "capabilities.json") >= 0) {
			// Read actual capabilities file from tests/boards/
			let real_path = path;
			// If path doesn't start with tests/, prepend it
			if (!match(path, /^tests\//)) {
				real_path = "tests/" + path;
			}
			try {
				return fs_real.readfile(real_path);
			} catch (e) {
				die(sprintf("Failed to read capabilities file: %s (%s)", real_path, e));
			}
		}
		if (index(path, "board.json") >= 0) {
			// Read actual board file from tests/boards/
			let real_path = path;
			// If path doesn't start with tests/, prepend it
			if (!match(path, /^tests\//)) {
				real_path = "tests/" + path;
			}
			try {
				return fs_real.readfile(real_path);
			} catch (e) {
				die(sprintf("Failed to read board file: %s (%s)", real_path, e));
			}
		}
		return null;
	},
	stat: function(path) {
		// Mock file stats - assume files exist
		return { type: 'regular' };
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
	board ??= 'eap101';
	return json(fs.readfile(sprintf("boards/%s/capabilities.json", board)));
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

		for (let incfile in fs_real.glob("../renderer/templates/services/*.uc")) {
			let m = match(incfile, /^.+\/([^\/]+)\.uc$/);
			if (m)
				push(rv, m[1]);
		}

		return rv;
	},
	lookup_metrics: function() {
		// Dynamic metrics discovery like the real renderer
		let rv = [];

		for (let incfile in fs_real.glob("../renderer/templates/metric/*.uc")) {
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


// Create test context with all mocks
function create_test_context(overrides) {
	// Initialize with board capabilities (unit tests use eap101 by default)
	let board = 'eap101';
	let capabilities = mock_capab(board);
	mock_ethernet = create_ethernet(capabilities, mock_fs, null);

	// Create board-specific cursor
	let cursor = create_mock_cursor(board);

	// Initialize wiphy with real board wiphy data
	mock_wiphy = create_wiphy(cursor, function(fmt, ...args) {
		printf("[W] " + sprintf(fmt, ...args) + "\n");
	});
	// Load real wiphy data from board-specific wiphy.json
	try {
		let wiphy_path = sprintf("boards/%s/wiphy.json", board);
		let wiphy_content = fs_real.readfile(wiphy_path);
		let wiphy_data = json(wiphy_content);
		mock_wiphy.phys = wiphy_data;
	} catch (e) {
		die(sprintf("Failed to read wiphy data from %s: %s", wiphy_path, e));
	}

	// Initialize routing table
	mock_routing_table = create_routing_table();

	// Reset mock files state for clean test runs
	mock_files.clear_generated_files();

	let result = {
		// Basic functions
		b, s,

		// UCI helpers
		uci_cmd,
		uci_set_string,
		uci_set_boolean,
		uci_set_number,
		uci_list_string,
		uci_section,
		uci_named_section,
		uci_output,
		uci_comment,

		// Mock system objects
		cursor: cursor,
		conn: mock_conn,
		fs: mock_fs,
		capab: capabilities,
		restrict: mock_restrict,
		default_config: mock_default_config,
		services: mock_services,
		ethernet: mock_ethernet,
		wiphy: mock_wiphy,
		routing_table: mock_routing_table,
		files: mock_files,
		events: mock_events,
		shell: mock_shell,

		// Mock utility functions
		warn: function(fmt, ...args) {
			printf("[W] " + sprintf(fmt, ...args) + "\n");
		},
		error: function(fmt, ...args) {
			printf("[E] " + sprintf(fmt, ...args) + "\n");
		},
		info: function(fmt, ...args) {
			printf("[I] " + sprintf(fmt, ...args) + "\n");
		},

	};

	// Manually merge overrides
	if (overrides) {
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
	}

	// Set test state in services mock for lookup_interfaces
	if (overrides && overrides.state) {
		result.services._test_state = overrides.state;
	} else if (overrides) {
		result.services._test_state = overrides;
	}

	// Set global state for ethernet library functions
	global.state = overrides || {};

	return result;
}

// Create board-specific test context with real device data
function create_board_test_context(test_data, board_data, capabilities, board_name) {
	// Use the board name passed from the test framework, default to eap101
	board_name ??= 'eap101';

	// Initialize ethernet with actual board capabilities
	mock_ethernet = create_ethernet(capabilities, mock_fs, null);

	// Create board-specific cursor
	let cursor = create_mock_cursor(board_name);

	// Initialize wiphy with board-specific wiphy data
	mock_wiphy = create_wiphy(cursor, function(fmt, ...args) {
		printf("[W] " + sprintf(fmt, ...args) + "\n");
	});
	try {
		let wiphy_path = sprintf("boards/%s/wiphy.json", board_name);
		let wiphy_content = fs_real.readfile(wiphy_path);
		let wiphy_data = json(wiphy_content);
		mock_wiphy.phys = wiphy_data;
	} catch (e) {
		die(sprintf("Failed to read board wiphy data from %s: %s", sprintf("boards/%s/wiphy.json", board_name), e));
	}

	// Initialize routing table
	mock_routing_table = create_routing_table();

	// Reset mock files state for clean test runs
	mock_files.clear_generated_files();

	let context = create_test_context(test_data);

	// Add board-specific data to context
	context.board = board_data;
	context.capab = capabilities;

	// Override cursor with board-specific one
	context.cursor = cursor;

	return context;
};

// Create full test context for toplevel.uc rendering
function create_full_test_context(state, board_data, capabilities, board_name) {
	let context = create_board_test_context(state, board_data, capabilities, board_name);

	// Add the validated state and all globals that renderer.uc passes to toplevel.uc
	context.state = state;
	context.location = '/';
	context.capab = capabilities;
	context.restrict = {};
	context.default_config = mock_default_config;
	context.latency = mock_latency;
	context.local_profile = mock_local_profile;
	
	// Add all UCI helper functions
	context.uci_cmd = uci_cmd;
	context.uci_set_string = uci_set_string;
	context.uci_set_boolean = uci_set_boolean;
	context.uci_set_number = uci_set_number;
	context.uci_set_raw = uci_set_raw;
	context.uci_list_string = uci_list_string;
	context.uci_list_number = uci_list_number;
	context.uci_section = uci_section;
	context.uci_named_section = uci_named_section;
	context.uci_set = uci_set;
	context.uci_list = uci_list;
	context.uci_output = uci_output;
	context.uci_comment = uci_comment;
	
	// Add utility functions
	context.tryinclude = tryinclude;
	
	return context;
};

// Export the functions
export { create_test_context, create_board_test_context, create_full_test_context };
