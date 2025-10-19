# Template Design Guide

This document outlines best practices and patterns for organizing ucode template files in the uconfig system.


### Template Hierarchy and Inclusion Patterns

The new structure follows a clear inclusion hierarchy:

1. **`toplevel.uc`** - Main orchestrator that calls other major templates
2. **Major templates** (`interface.uc`, `radio.uc`, etc.) - Include related sub-templates
3. **Sub-templates** (`interface/*.uc`, `services/*.uc`) - Focused, specific functionality

Templates should follow this hierarchical organization within each file:

```ucode
{%
	// 1. Constants (grouped by purpose)
	const MODE_CONSTANTS = [ 'value1', 'value2' ];
	const CONFIG_PATHS = {
		key: '/path/to/config'
	};

	// 2. Helper functions (grouped by prefix)
	
	// has_ functions - check for existence/availability
	function has_feature() { ... }
	
	// is_ functions - boolean checks/validation
	function is_valid_mode() { ... }
	
	// match_ functions - value mapping/selection
	function match_setting() { ... }
	
	// normalize_ functions - data transformation
	function normalize_value() { ... }
	
	// supports_ functions - capability checking
	function supports_feature() { ... }
	
	// validate_ functions - complex validation logic
	function validate_config() { ... }
	
	// Utility functions - other helpers
	function add_attributes() { ... }
	function generate_file() { ... }
	function setup_config() { ... }

	// 3. Configuration generation functions (ordered by template usage)
	function generate_basic_config() { ... }
	function generate_advanced_config() { ... }
	
	// 4. Main logic and setup
	let processed_data = process_input();
	setup_configuration();
%}

# Template output section
{%  for item in items: %}
{{ generate_basic_config(item) }}
{{ generate_advanced_config(item) }}
{%  endfor %}
```

## Design Principles

### 1. Constants at the Top
- Only extract arrays `[]` and static objects `{}` into named constants
- **Do NOT make simple strings or numbers constant** - use them directly
- Group related constants together
- Use SCREAMING_SNAKE_CASE for constant names
- Place constants before any functions

**Example:**
```ucode
const BASIC_BSS_MODES = [ 'ap', 'sta' ];
const COMPATIBLE_6G_MODES = [ 'wpa3', 'wpa3-mixed', 'wpa3-192', 'sae', 'sae-mixed', 'owe' ];
const CERTIFICATES = {
	ca_certificate: '/etc/uconfig/certificates/ca.pem',
	certificate: '/etc/uconfig/certificates/cert.pem',
	private_key: '/etc/uconfig/certificates/cert.key'
};

// WRONG - don't make simple strings/numbers constant:
// const PORT = '123';  
// const PROTOCOL = 'udp';

// RIGHT - use directly in code:
// push(output, sprintf('set ntp.port=123'));
// push(output, sprintf('set ntp.proto=udp'));
```

### 2. Helper Function Organization
Group helper functions by their prefix to create logical sections:

- **`has_*`** - Existence checks, availability tests
- **`is_*`** - Boolean validation, state checking  
- **`match_*`** - Value mapping, selection logic
- **`normalize_*`** - Data transformation, standardization
- **`supports_*`** - Feature/capability checking
- **`validate_*`** - Complex validation with return objects

### 3. Configuration Generation Functions
- Extract large template blocks into focused functions
- Each function should handle one specific configuration area
- Order functions by the sequence they appear in the template
- Use consistent array-based output pattern:

**Pattern:**
```ucode
function generate_feature_config(section, params) {
	if (!should_generate_feature())
		return '';
	
	let output = [];
	push(output, sprintf('set config.%s.param=%s', section, value));
	push(output, sprintf('set config.%s.flag=%s', section, flag));
	push(output, ''); // Always add blank line at end of section

	return join('\n', output);
}
```

**Guard conditions first:**
```ucode
function generate_optional_config(section, data) {
	if (!data || !data.enabled)
		return '';

	// ... rest of function
}
```

### 4. Function Naming Conventions

#### Helper Functions
- Use descriptive prefixes (`has_`, `is_`, `match_`, etc.)
- Be specific about what is being checked/processed
- Examples: `is_6g_band()`, `has_local_radius()`, `supports_bss_mode()`

#### Generation Functions  
- Use `generate_*` prefix for configuration output functions
- Name should indicate the configuration area handled
- Examples: `generate_crypto_base()`, `generate_roaming_config()`

### 5. Template Loop Simplification
Replace large inline template blocks with function calls:

**Before:**
```ucode
{% for item in items: %}
{%   if (complex_condition): %}
set config.item.param1=value1
set config.item.param2=value2  
set config.item.param3=value3
{%   endif %}
{%   if (another_condition): %}
set config.item.flag1=true
set config.item.flag2=false
{%   endif %}
{% endfor %}
```

**After:**
```ucode
{%  for item in items: %}
{{ generate_basic_config(item) }}
{{ generate_optional_config(item) }}
{%  endfor %}
```

### 6. UCI Helper Function Usage
Use the new UCI helper functions for consistent output formatting:

```ucode
function generate_config_block(section, params) {
	let output = [];
	
	uci_comment(output, '### generate config block');
	uci_set_string(output, `config.${section}.param`, params.value);
	uci_set_boolean(output, `config.${section}.enabled`, params.enabled);
	uci_set_number(output, `config.${section}.port`, params.port);
	uci_list_string(output, `config.${section}.servers`, params.server);
	uci_section(output, 'config block');
	uci_named_section(output, `config.${section}`, 'block-type');

	return uci_output(output);
}
```

**UCI Helper Functions:**
- **`uci_comment(output, text)`** - Add comments (replaces `push(output, comment)`)
- **`uci_set_string(output, key, value)`** - Set string values with proper escaping
- **`uci_set_boolean(output, key, value)`** - Set boolean values (true/false)
- **`uci_set_number(output, key, value)`** - Set numeric values
- **`uci_list_string(output, key, value)`** - Add to UCI list
- **`uci_section(output, type)`** - Create anonymous UCI sections
- **`uci_named_section(output, name, type)`** - Create named UCI sections
- **`uci_output(output)`** - Format final UCI output with proper spacing

**Key Rules:**
- **Always use `uci_output(output)` to return** - This ensures proper UCI formatting and spacing
- **Use specific UCI helpers** instead of raw `sprintf()` calls for better validation
- **Group variable declarations** with blank line after, and blank line before return

### 7. Traceability Comments
Add comments for debugging and traceability:

**Template file headers:**
Templates should start with `{%` and use `uci_comment()` to add file headers within generation functions. This ensures that templates generating no output don't show the header comment:
```ucode
{%
	// All logic, constants, helper functions here
	
	function generate_basic_config() {
		let output = [];
		
		uci_comment(output, '# generated by filename.uc');
		uci_comment(output, '### generate basic configuration');
		// ... configuration logic
		
		return uci_output(output);
	}
	// ...
%}

{{ generate_basic_config() }}
{{ generate_advanced_config() }}
```

**Template section headers:**
Use `##` for logical sections within templates:
```ucode
{{ generate_basic_config() }}

## Crypto settings
{{ generate_crypto_config() }}

## AP specific settings  
{{ generate_ap_config() }}
```

**Function identification:**
Each `generate_*()` function should start its output with file header and descriptive comment using `uci_comment()`:
```ucode
function generate_firewall_rules() {
	let output = [];

	uci_comment(output, '# generated by filename.uc');
	uci_comment(output, '### generate firewall rules');
	uci_set_string(output, 'firewall.rule', value);

	return uci_output(output);
}
```

**Comment hierarchy:**
- `# generated by filename.uc` - File header (added via `uci_comment()` in first generation function)
- `##` - Template section headers
- `###` - Function identification within generated output (added via `uci_comment()`)

This pattern ensures that templates generating no output remain completely empty, while templates that do generate output are properly traced back to their source template and specific function.

### 8. Code Formatting Standards
Follow consistent formatting rules for ucode templates:

**Indentation:**
- Use tabs for all indentation, not spaces
- No trailing whitespace or tabs on empty lines
- Empty lines should be completely empty

**Conditional Statements:**
```ucode
// Single statement if - NO braces (even if statement spans multiple lines)
if (condition)
	return value;

if (condition)
	return {
		key1: value1,
		key2: value2
	};

// Multiple statements if - USE braces
if (condition) {
	statement1();
	statement2();
}

// If-else: both single statement - NO braces
if (condition)
	return true;
else
	return false;

// If-else: one or both have multiple statements - BOTH use braces
if (condition) {
	statement1();
	statement2();
} else {
	statement3();
}

// Even if one block is single statement, both need braces if either has multiple statements
if (condition) {
	return value;
} else {
	statement1();
	statement2();
}
```

**Function Formatting:**
```ucode
function example_function() {
	// Variable declarations first
	let output = [];
	let result = calculate_something();

	// Blank line after variable declaration block
	// Empty lines should have no whitespace
	if (simple_check())
		return;
	
	if (complex_check()) {
		do_something();
		do_another_thing();
	}

	// Always blank line before return statement
	return result;
}

function generate_config_example() {
	let output = [];
	let config_value = get_config();

	// Blank line separates variable declarations from logic
	push(output, '### generate example configuration');
	push(output, sprintf('set config.value=%s', config_value));

	if (has_optional_setting())
		push(output, sprintf('set config.optional=%s', get_optional()));

	// Always blank line before return
	return join('\n', output);
}
```

**Common Formatting Errors to Avoid:**
- ❌ Braces on single-statement if statements
- ❌ Spaces for indentation (use tabs)
- ❌ Whitespace on empty lines
- ❌ Inconsistent indentation levels
- ❌ Mixed tabs and spaces
- ❌ Missing blank line after variable declarations
- ❌ Missing blank line before return statements
- ❌ No separation between logical blocks

## Refactoring Checklist

When refactoring an existing template:

### Phase 1: Extract Constants
- [ ] Identify all magic strings and numbers
- [ ] Create named constants at the top
- [ ] Group related constants together
- [ ] Update all references to use constants

### Phase 2: Organize Helper Functions
- [ ] Identify all helper functions
- [ ] Group by prefix (has_, is_, match_, etc.)
- [ ] Move to top of file after constants
- [ ] Remove any duplicate functions

### Phase 3: Extract Configuration Generation
- [ ] Identify large template blocks (>5 lines)
- [ ] Extract into focused generation functions
- [ ] Use array-based output pattern
- [ ] Order functions by template call sequence

### Phase 4: Simplify Main Template
- [ ] Replace inline blocks with function calls
- [ ] Ensure clean, readable template structure
- [ ] Verify all functions are called in correct order

## Benefits of This Pattern

1. **Maintainability** - Related functionality is grouped together
2. **Readability** - Clear separation of concerns
3. **Reusability** - Helper functions can be reused across the template  
4. **Testability** - Individual functions can be tested in isolation
5. **Debugging** - Easier to locate and fix issues in specific areas
6. **Consistency** - Standardized patterns across all templates

## Anti-Patterns to Avoid

1. **Scattered constants** - Magic values spread throughout the file
2. **Monolithic functions** - Single functions handling multiple concerns
3. **Deep nesting** - Complex nested conditionals in templates
4. **Duplicate logic** - Same validation/generation code repeated
5. **Template literals** - Using `sprintf()` with multi-line strings instead of arrays
6. **Mixed concerns** - Configuration logic mixed with template output

This pattern was successfully applied to reduce `ssid.uc` from 388 lines of complex, mixed logic to a well-organized, maintainable structure with clear separation of concerns.

## New Template Inclusion Patterns

### Orchestrator Templates
Main orchestrator templates (like `toplevel.uc`) use generation functions to coordinate sub-templates:

```ucode
// Configuration generation functions
function generate_services_config() {
	state.services ??= {};
	for (let service in services.lookup_services()) {
		tryinclude('services/' + service + '.uc', {
			location: '/services/' + service,
			[service]: state.services[service] || {},
			state,
		});
	}
}

function generate_interface_config() {
	function iterate_interfaces(role) {
		for (let i, interface in state.interfaces) {
			if (interface.role != role)
				continue;
			include('interface.uc', {
				location: '/interfaces/' + i,
				interface,
				vlans_upstream: vlan_data.vlans_upstream
			});
		}
	}

	iterate_interfaces("upstream");
	iterate_interfaces("downstream");
}

// Main execution
generate_services_config();
generate_interface_config();
```

### Sub-template Inclusion
Templates include focused sub-templates for specific functionality:

```ucode
// In interface.uc - includes sub-templates with context
{% if (crypto.eap_local): %}
{%   files.add_named(crypto.eap_user, render('../eap_users.uc', { users: crypto.eap_local.users })); %}
{% endif %}

// Direct inclusion for port forwarding rules
{% generate_port_forward_rules(interface, name) %}

// Inside the function:
function generate_port_forward_rules(interface, name) {
	for (let forward in interface.ipv4?.port_forward)
		include('firewall/forward.uc', {
			forward,
			family: 'ipv4',
			source_zone: ethernet.find_interface('upstream', interface.vlan?.id),
			destination_zone: name,
			destination_subnet: interface.ipv4.subnet
		});
}
```

### Template Context Passing
Templates pass rich context objects to sub-templates:

```ucode
// Comprehensive context passing
tryinclude('services/' + service + '.uc', {
	location: '/services/' + service,    // Location path for tracing
	[service]: state.services[service] || {}, // Service-specific config
	state,                               // Global state access
});

// Interface-specific context
include('interface.uc', {
	location: '/interfaces/' + i,
	interface,                           // Interface configuration
	vlans_upstream: vlan_data.vlans_upstream // Shared VLAN data
});
```

### Service Discovery Pattern
Templates use service discovery for dynamic inclusion:

```ucode
// Service templates are discovered and included dynamically
for (let service in services.lookup_services()) {
	tryinclude('services/' + service + '.uc', { /* context */ });
}

// Interface discovery for service binding
let interfaces = services.lookup_interfaces('radius-server');
```

## Template File Naming Conventions

### Directory Structure Rules
- **`services/*.uc`** - Service-specific templates (ntp, ssh, radius, etc.)
- **`interface/*.uc`** - Interface configuration sub-templates
- **`interface/firewall/*.uc`** - Firewall rule sub-templates
- **`interface/easymesh*.uc`** - EasyMesh specific templates

### File Naming Patterns
- Use **kebab-case** for multi-word filenames: `quality-of-service.uc`, `bridge-vlan.uc`
- Use **descriptive names** that match functionality: `firewall/forward.uc`, `firewall/allow.uc`
- **Service templates** should match service names discoverable by `services.lookup_services()`

## Early Validation and Normalization Patterns

### Validation-First Approach
Templates now perform validation and early returns to prevent invalid configurations:

```ucode
// Early validation with strict mode and error handling
function validate_uuid() {
	if (!is_valid_uuid(state.uuid)) {
		state.strict = true;
		error('Configuration must contain a valid UUID. Rejecting whole file');
		return false;
	}
	return true;
}

function validate_upstream_interfaces() {
	let upstream;
	for (let i, interface in state.interfaces) {
		if (!is_upstream_interface(interface))
			continue;
		upstream = interface;
	}

	if (!upstream) {
		state.strict = true;
		error('Configuration must contain at least one valid upstream interface. Rejecting whole file');
		return false;
	}
	return true;
}

// Early validation prevents further processing of invalid configs
if (!validate_uuid())
	return;

if (!validate_upstream_interfaces())
	return;
```

### Data Normalization Pipeline
Templates normalize data structures before processing:

```ucode
// Normalization functions modify data in-place
function normalize_interfaces() {
	for (let i, interface in state.interfaces)
		if (is_disabled_interface(interface))
			delete state.interfaces[i];
}

function normalize_interface_names() {
	for (let name, interface in state.interfaces)
		interface.name = name;
}

// Normalization pipeline runs before main logic
normalize_interfaces();
normalize_interface_names();
normalize_interface_indexes();
```

### Service Availability Checks
Service templates validate availability before generating configuration:

```ucode
// Service availability pattern
function has_radius_service() {
	return services.is_present("radius");
}

function has_radius_interfaces() {
	let interfaces = services.lookup_interfaces("radius-server");
	return length(interfaces) > 0;
}

// Early return if service not available
if (!has_radius_service())
	return;

let enable = has_radius_interfaces() && users;
services.set_enabled("radius", enable);

if (!enable)
	return;
```

### Configuration Guard Patterns
Individual configuration functions use guard clauses:

```ucode
function generate_optional_config(section, data) {
	// Guard clause prevents unnecessary processing
	if (!data || !data.enabled)
		return '';

	// Main configuration logic only runs when needed
	let output = [];
	uci_comment(output, '### generate optional configuration');
	// ...
	return uci_output(output);
}
```
