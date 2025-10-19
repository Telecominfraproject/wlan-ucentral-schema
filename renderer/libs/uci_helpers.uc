// UCI helper functions for uCentral schema renderer
// Extracted from renderer.uc to enable code sharing between renderer and tests

"use strict";

/**
 * Formats a given input value as uci boolean value.
 *
 * @memberof uCentral.prototype
 * @param {*} val The value to format
 * @returns {string}
 * Returns '1' if the given value is truish (not `false`, `null`, `0`,
 * `0.0` or an empty string), or `0` in all other cases.
 */
function b(val) {
	return val ? '1' : '0';
}

/**
 * Formats a given input value as single quoted string, honouring uci
 * specific escaping semantics.
 *
 * @memberof uCentral.prototype
 * @param {*} str The string to format
 * @returns {string}
 * Returns an empty string if the given input value is `null` or an
 * empty string. Returns the escaped and quoted string in all other
 * cases.
 */
function s(str) {
	if (str === null || str === '')
		return '';
	return sprintf("'%s'", replace(str, /'/g, "'\\''"));
}

// UCI command helpers to safely handle null/undefined values
function uci_cmd(cmd_type, path, value, formatter) {
	// Skip if value is null (except for 'add' which has no value)
	if (cmd_type !== 'add' && value === null)
		return '';
	
	if (cmd_type === 'add') {
		return sprintf('%s %s', cmd_type, path);
	} else {
		let formatted_value = formatter ? formatter(value) : s(value);
		return sprintf('%s %s=%s', cmd_type, path, formatted_value);
	}
}

// Type-specific set helpers
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

// Type-specific add_list helpers
function uci_list_string(output, path, value) {
	let cmd = uci_cmd('add_list', path, value, s);
	if (cmd) push(output, cmd);
}

function uci_list_number(output, path, value) {
	let cmd = uci_cmd('add_list', path, value, (v) => v);
	if (cmd) push(output, cmd);
}

// Section helpers
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

// Generic helpers for backwards compatibility
function uci_set(output, path, value) {
	uci_set_string(output, path, value);
}

function uci_list(output, path, value) {
	uci_list_string(output, path, value);
}

// Helper to finalize UCI output with proper spacing
function uci_output(output) {
	push(output, '');
	return join('\n', output);
}

// Helper to add comments to UCI output
function uci_comment(output, comment) {
	push(output, comment);
}

// Export each function separately
export {
	b,
	s,
	uci_cmd,
	uci_set_string,
	uci_set_boolean,
	uci_set_number,
	uci_set_raw,
	uci_list_string,
	uci_list_number,
	uci_section,
	uci_named_section,
	uci_set,
	uci_list,
	uci_output,
	uci_comment
};