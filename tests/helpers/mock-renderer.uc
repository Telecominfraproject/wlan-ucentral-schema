// Mock renderer environment for testing templates

"use strict";

import * as fs from 'fs';
import { 
	b, s, uci_cmd, uci_set_string, uci_set_boolean, uci_set_number, uci_set_raw,
	uci_list_string, uci_list_number, uci_section, uci_named_section, 
	uci_set, uci_list, uci_output, uci_comment
} from '../../renderer/libs/uci_helpers.uc';
import { create_ethernet } from '../../renderer/libs/ethernet.uc';

// Mock UCI cursor
let mock_cursor = {
	load: function(config) {
		// Mock loading UCI config
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
					let fs_real = require("fs");
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
					let fs_real = require("fs");
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
					let fs_real = require("fs");
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
			let fs_real = require("fs");
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
			let fs_real = require("fs");
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
		return ["log", "ssh", "ntp", "lldp", "ieee8021x"]; // Common services
	},
	lookup_metrics: function() {
		// Mock implementation - return common metrics found in tests
		return ["health", "statistics", "telemetry", "realtime", "wifi_frames", "wifi_scan", "dhcp_snooping"];
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


// Create test context with all mocks
function create_test_context(overrides) {
	// Initialize ethernet with real board capabilities (unit tests use eap101)
	let capabilities = mock_capab(null);
	mock_ethernet = create_ethernet(capabilities, mock_fs, null);


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
		cursor: mock_cursor,
		conn: mock_conn,
		fs: mock_fs,
		capab: capabilities,
		restrict: mock_restrict,
		default_config: mock_default_config,
		services: mock_services,
		ethernet: mock_ethernet,
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
function create_board_test_context(test_data, board_data, capabilities) {
	// Initialize ethernet with actual board capabilities
	mock_ethernet = create_ethernet(capabilities, mock_fs, null);

	let context = create_test_context(test_data);

	// Add board-specific data to context
	context.board = board_data;
	context.capab = capabilities;

	// Enhanced wiphy mock based on board capabilities
	context.wiphy = {
		lookup_by_band: function(band) {
			let phys = [];
			for (let phy_path, phy_data in capabilities.wifi || {}) {
				if (index(phy_data.band, band) >= 0) {
					push(phys, {
						...phy_data,
						path: phy_path
					});
				}
			}
			return phys;
		}
	};

	return context;
};

// Create full test context for toplevel.uc rendering
function create_full_test_context(state, board_data, capabilities) {
	let context = create_board_test_context({}, board_data, capabilities);
	
	// Add the validated state and all globals that renderer.uc passes to toplevel.uc
	context.state = state;
	context.location = '/';
	context.cursor = mock_cursor;
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
