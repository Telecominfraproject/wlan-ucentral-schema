// Mock renderer environment for testing templates

"use strict";

import * as fs from 'fs';

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
				if (path.indexOf("capabilities.json") >= 0)
					return '{"network": {"upstream": ["eth0"], "downstream": ["eth1"]}}';
				if (path.indexOf("board.json") >= 0)
					return '{"network": {"eth0": {"device": "eth0"}}}';
				if (path.indexOf("qos.json") >= 0 || path.indexOf("/usr/share/ucentral/qos.json") >= 0) {
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
		if (path.indexOf("capabilities.json") >= 0)
			return '{"network": {"upstream": ["eth0"], "downstream": ["eth1"]}}';
		if (path.indexOf("board.json") >= 0)
			return '{"network": {"eth0": {"device": "eth0"}}}';
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

// Mock capabilities
let mock_capab = {
	network: {
		upstream: ["eth0"],
		downstream: ["eth1"]
	},
	switch_ports: {},
	macaddr: {
		wan: "00:11:22:33:44:55",
		lan: "00:11:22:33:44:56"
	},
	platform: "ap"
};

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

// UCI helper functions (from renderer.uc)
function b(val) {
	return val ? '1' : '0';
}

function s(str) {
	if (str === null || str === '')
		return '';
	return sprintf("'%s'", replace(str, /'/g, "'\\''"));
}

function uci_cmd(cmd_type, path, value, formatter) {
	if (cmd_type !== 'add' && value === null)
		return '';
	
	if (cmd_type === 'add') {
		return sprintf('%s %s', cmd_type, path);
	} else {
		let formatted_value = formatter ? formatter(value) : s(value);
		return sprintf('%s %s=%s', cmd_type, path, formatted_value);
	}
}

function uci_set_string(output, path, value) {
	let cmd = uci_cmd('set', path, value, s);
	if (cmd) push(output, cmd);
}

function uci_set_boolean(output, path, value) {
	let cmd = uci_cmd('set', path, value, b);
	if (cmd) push(output, cmd);
}

function uci_set_number(output, path, value) {
	let cmd = uci_cmd('set', path, value, (v) => v);
	if (cmd) push(output, cmd);
}

function uci_set_raw(output, path, value) {
	let cmd = uci_cmd('set', path, value, (v) => v);
	if (cmd) push(output, cmd);
}

function uci_list_number(output, path, value) {
	let cmd = uci_cmd('add_list', path, value, (v) => v);
	if (cmd) push(output, cmd);
}

function uci_set(output, path, value) {
	let cmd = uci_cmd('set', path, value, s);
	if (cmd) push(output, cmd);
}

function uci_list(output, path, value) {
	let cmd = uci_cmd('add_list', path, value, s);
	if (cmd) push(output, cmd);
}

function uci_list_string(output, path, value) {
	let cmd = uci_cmd('add_list', path, value, s);
	if (cmd) push(output, cmd);
}

function uci_section(output, path) {
	let cmd = uci_cmd('add', path);
	if (cmd) push(output, cmd);
}

function uci_named_section(output, name, type) {
	if (name === null)
		return;
	let cmd = sprintf('set %s=%s', name, type);
	push(output, cmd);
}

function uci_output(output) {
	push(output, '');
	return join('\n', output);
}

function uci_comment(output, comment) {
	push(output, comment);
}

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

// Mock ethernet object  
let mock_ethernet = {
	ports: {},
	calculate_name: function(interface) {
		// Generate interface name based on interface properties
		if (interface && interface.name)
			return interface.name;
		if (interface && interface.role)
			return interface.role;
		return "mock_interface";
	},
	lookup_by_interface_spec: function(interface) {
		// Return mock port names based on interface ethernet config
		let ports = [];
		if (interface && interface.ethernet) {
			for (let eth in interface.ethernet) {
				if (eth.select_ports) {
					for (let port in eth.select_ports) {
						push(ports, lc(port)); // Convert to lowercase like real system
					}
				}
			}
		}
		return ports;
	},
	find_interface: function(role, vlan_id) {
		// Mock interface lookup
		return role + (vlan_id ? "_" + vlan_id : "");
	},
	lookup_by_select_ports: function(select_ports) {
		// Convert select_ports array to actual port names
		let ports = [];
		if (select_ports) {
			for (let port in select_ports) {
				if (port == "WAN") {
					push(ports, "eth0");
				} else if (port == "LAN*") {
					push(ports, "eth1");
				} else {
					push(ports, lc(port));
				}
			}
		}
		return ports;
	},
	lookup_by_interface_vlan: function(interface) {
		// Mock function for VLAN interface lookup used by dhcp_snooping
		// Returns array of interface names for upstream interfaces with VLANs
		if (interface.vlan && interface.vlan.id) {
			return [interface.name + "_" + interface.vlan.id];
		} else {
			return [interface.name || "upstream"];
		}
	},
	has_vlan: function(interface) {
		// Mock implementation matching renderer.uc
		return interface.vlan && interface.vlan.id;
	},
	reserve_port: function(port) {
		// Mock implementation - remove port from available ports
		delete this.ports[port];
	},
	switch_by_interface_vlan: function(interface, raw) {
		// Mock implementation - return null since most tests don't use switch config
		return null;
	},
	calculate_names: function(interface) {
		// Mock implementation - return simple name array
		let name = this.calculate_name(interface);
		return [name]; // Simplified - real version handles IPv4/IPv6 dual stack
	},
	calculate_ipv4_name: function(interface) {
		// Mock implementation - return simple name
		return this.calculate_name(interface);
	},
	calculate_ipv6_name: function(interface) {
		// Mock implementation - return simple name
		return this.calculate_name(interface);
	}
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
	
	write_debug_output: function(test_name, output) {
		// Write test output to /tmp/ucentral-test-output/ for debugging
		let debug_dir = "/tmp/ucentral-test-output";
		try {
			fs.mkdir(debug_dir);
		} catch (e) {
			// Directory might already exist
		}
		
		let debug_file = debug_dir + "/" + test_name + ".uci";
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

// Create test context with all mocks  
function create_test_context(overrides) {
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
		capab: mock_capab,
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
	
	return result;
}

// Create board-specific test context with real device data
function create_board_test_context(test_data, board_data, capabilities) {
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