// Mock renderer environment for testing templates

"use strict";

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
	lookup_services: function() {
		return ["log", "ssh", "ntp", "lldp", "ieee8021x"]; // Common services
	},
	_test_state: null // Will be set by test context
};

// Mock ethernet object  
let mock_ethernet = {
	ports: {},
	calculate_name: function(interface) {
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
	}
};

// Mock files object
let mock_files = {
	add_named: function(path, content) {
		// Mock file addition
	},
	add_anonymous: function(location, name, content) {
		return "/tmp/mock/" + name;
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
			result[key] = value;
		}
	}
	
	// Set test state in services mock for lookup_interfaces
	if (overrides && overrides.state) {
		result.services._test_state = overrides.state;
	}
	
	return result;
}

// Export the function
export { create_test_context };