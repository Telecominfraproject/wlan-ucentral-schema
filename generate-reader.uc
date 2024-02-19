#!/usr/bin/env -S ucode -R
"use strict";

let fs = require("fs");
let math = require("math");

function to_property_name(name)
{
	return replace(replace(
		name, //replace(name, /-(.)/g, (_, c) => uc(c)),
		/[^A-Za-z0-9_]+/g,
		'_'
	), /^[0-9]/, '_$&');
}

function to_method_name(verb, name)
{
	return verb + replace(
		replace(name, /(^|-|\.)(.)/g, (_, p, c) => uc(c)),
		/[^A-Za-z0-9_]+/g,
		'_'
	);
}

function to_json_ptr(propertyName)
{
	return replace(propertyName, /[~\/]/g, m => (m == '~' ? '~0' : '~1'));
}

function to_text_list(listValue, quoteItems)
{
	let res = [];
	let lastidx = length(listValue) - 1;

	for (let i, v in listValue) {
		if (i > 0)
			push(res, (i < lastidx) ? ', ' : ' or ');

		push(res, quoteItems ? sprintf('%J', v) : v);
	}

	return join('', res);
}


let GeneratorProto = {
	format_validators: {
		"uc-cidr4": {
			desc: 'IPv4 CIDR',
			code: [
				'let m = match(value, /^(auto|[0-9.]+)\\/([0-9]+)$/);',
				'return m ? ((m[1] == "auto" || length(iptoarr(m[1])) == 4) && +m[2] <= 32) : false;'
			]
		},
		"uc-cidr6": {
			desc: 'IPv6 CIDR',
			code: [
				'let m = match(value, /^(auto|[0-9a-fA-F:.]+)\\/([0-9]+)$/);',
				'return m ? ((m[1] == "auto" || length(iptoarr(m[1])) == 16) && +m[2] <= 128) : false;'
			]
		},
		"uc-cidr": {
			desc: 'IPv4 or IPv6 CIDR',
			code: [
				'let m = match(value, /^(auto|[0-9a-fA-F:.]+)\\/([0-9]+)$/);',
				'if (!m) return false;',
				'let l = (m[1] == "auto") ? 16 : length(iptoarr(m[1]));',
				'return (l > 0 && +m[2] <= (l * 8));'
			]
		},
		"uc-mac": {
			desc: 'MAC address',
			code: [
				'return match(value, /^[0-9a-f][0-9a-f]:[0-9a-f][0-9a-f]:[0-9a-f][0-9a-f]:[0-9a-f][0-9a-f]:[0-9a-f][0-9a-f]:[0-9a-f][0-9a-f]$/i);'
			]
		},
		"uc-mobility": {
                        desc: 'Mobility Domain',
                        code: [
                                'return match(value, /^[0-9a-f][0-9a-f][0-9a-f][0-9a-f]$/i);'
                        ]
                },
		"uc-host": {
			desc: 'hostname or IP address',
			code: [
				'if (length(iptoarr(value)) != 0) return true;',
				'if (length(value) > 255) return false;',
				'let labels = split(value, ".");',
				'return (length(filter(labels, label => !match(label, /^([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9])$/))) == 0 && length(labels) > 0);'
			]
		},
		"uc-timeout": {
			desc: 'timeout value',
			code: [
				'return match(value, /^[0-9]+[smhdw]$/);'
			]
		},
		"uc-base64": {
			desc: 'base64 encoded data',
			code: [
				'return b64dec(value) != null;'
			]
		},
		"uc-portrange": {
			desc: 'network port range',
			code: [
				'let ports = match(value, /^([0-9]|[1-9][0-9]*)(-([0-9]|[1-9][0-9]*))?$/);',
				'if (!ports) return false;',
				'let min = +ports[1], max = ports[2] ? +ports[3] : min;',
				'return (min <= 65535 && max <= 65535 && max >= min);'
			]
		},
		"hostname": {
			desc: 'hostname',
			code: [
				'if (length(value) > 255) return false;',
				'let labels = split(value, ".");',
				'return (length(filter(labels, label => !match(label, /^([a-zA-Z0-9]{1,2}|[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9])$/))) == 0 && length(labels) > 0);'
			]
		},
		"uc-fqdn": {
			desc: 'fully qualified domain name',
			code: [
				'if (length(value) > 255) return false;',
				'let labels = split(value, ".");',
				'return (length(filter(labels, label => !match(label, /^([a-zA-Z0-9]{1,2}|[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9])$/))) == 0 && length(labels) > 1);'
			]
		},
		"uc-ip": {
			desc: 'IPv4 or IPv6 address',
			code: [
				'return (length(iptoarr(value)) == 4 || length(iptoarr(value)) == 16);'
			]
		},
		"ipv4": {
			desc: 'IPv4 address',
			code: [
				'return (length(iptoarr(value)) == 4);'
			]
		},
		"ipv6": {
			desc: 'IPv6 address',
			code: [
				'return (length(iptoarr(value)) == 16);'
			]
		},
		"uri": {
			desc: 'URI',
			code: [
				'if (index(value, "data:") == 0) return true;',
				'let m = match(value, /^[a-z+-]+:\\/\\/([^\\/]+).*$/);',
				'if (!m) return false;',
				'if (length(iptoarr(m[1])) != 0) return true;',
				'if (length(m[1]) > 255) return false;',
				'let labels = split(m[1], ".");',
				'return (length(filter(labels, label => !match(label, /^([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9])$/))) == 0 && length(labels) > 0);'
			]
		}
	},

	type_keywords: {
		number: [
			'minimum', 'maximum', 'exclusiveMinimum', 'exclusiveMaximum',
			'multipleOf'
		],
		string: [
			'pattern', 'format', 'minLength', 'maxLength'
		],
		array: [
			'minItems', 'maxItems', 'items'
		],
		object: [
			'additionalProperties', 'minProperties', 'maxProperties',
			'properties', 'propertyNames'
		]
	},

	has_type_keywords: function(typeName, valueSpec) {
		if (!exists(this.type_keywords, typeName))
			return false;

		for (let keyword in this.type_keywords[typeName])
			if (exists(valueSpec, keyword))
				return true;

		return false;
	},

	is_ref: function(value)
	{
		return (
			type(value) == "object" &&
			exists(value, "$ref") &&
			//length(value) == 1 &&
			type(value["$ref"]) == "string"
		) ? value["$ref"] : null;
	},

	emit_test_expression: function(indent, condExpr, errorMsg)
	{
		this.print(indent, 'if (%s)', condExpr);
		this.print(indent, '	push(errors, [ location, %J ]);', errorMsg);
		this.print(indent, '');
	},

	emit_generic_tests: function(indent, valueExpr, valueSpec)
	{
		let typeMap = {
			string: 'type(%s) != "string"',
			number: '!(type(%s) in [ "int", "double" ])',
			integer: 'type(%s) != "int"',
			boolean: 'type(%s) != "bool"',
			array: 'type(%s) != "array"',
			object: 'type(%s) != "object"',
			null: 'type(%s) != null'
		};

		if (exists(valueSpec, 'type')) {
			let types = filter(
				(type(valueSpec.type) == 'array') ? valueSpec.type : [ valueSpec.type ],
				typeName => {
					return exists(typeMap, typeName)
						? true
						: (warn("Unrecognized type name '" + type + "'.\n"), false);
				}
			);

			this.emit_test_expression(indent,
				join(' && ', map(types, typeName => sprintf(typeMap[typeName], valueExpr))),
				sprintf('must be of type %s', to_text_list(types)));
		}

		if (type(valueSpec.enum) == 'array' && length(valueSpec.enum) > 0)
			this.emit_test_expression(indent,
				sprintf('!(%s in %J)', valueExpr, valueSpec.enum),
				sprintf('must be one of %s', to_text_list(valueSpec.enum, true)));

		if (exists(valueSpec, 'const'))
			this.emit_test_expression(indent,
				sprintf('%s != %J', valueExpr, valueSpec.const),
				sprintf('must have value %J', valueSpec.const));
	},

	emit_number_tests: function(indent, valueExpr, valueSpec)
	{
		if (!this.has_type_keywords('number', valueSpec))
			return;

		this.print(indent, 'if (type(%s) in [ "int", "double" ]) {', valueExpr);

		if (exists(valueSpec, 'multipleOf')) {
			this.emit_test_expression(indent + '\t',
				sprintf('%s / %J != int(%s / %J)', valueExpr, valueSpec.multipleOf, valueExpr, valueSpec.multipleOf),
				sprintf('must be divisible by %J', valueSpec.multipleOf));
		}

		let constraints = {
			'maximum': [ '>', 'lower than or equal to' ],
			'minimum': [ '<', 'bigger than or equal to' ],
			'exclusiveMaximum': [ '>=', 'lower than' ],
			'exclusiveMinimum': [ '<=', 'bigger than' ]
		};

		for (let keyword, op_desc in constraints) {
			if (exists(valueSpec, keyword))
				this.emit_test_expression(indent + '\t',
					sprintf('%s %s %J', valueExpr, op_desc[0], valueSpec[keyword]),
					sprintf('must be %s %J', op_desc[1], valueSpec[keyword]));
		}

		this.print(indent, '}\n');
	},

	emit_string_tests: function(indent, valueExpr, valueSpec)
	{
		if (!this.has_type_keywords('string', valueSpec))
			return;

		this.print(indent, 'if (type(%s) == "string") {', valueExpr);

		if (exists(valueSpec, 'pattern')) {
			try {
				regexp(valueSpec.pattern);

				this.emit_test_expression(indent + '\t',
					sprintf('!match(%s, regexp(%J))', valueExpr, valueSpec.pattern),
					sprintf('must match regular expression /%s/', valueSpec.pattern));
			}
			catch (e) {
				warn("Uncompilable regular expression '" + valueSpec.pattern + "': " + e + '.\n');
			}
		}

		if (exists(valueSpec, 'maxLength')) {
			this.emit_test_expression(indent + '\t',
				sprintf('length(%s) > %J', valueExpr, valueSpec.maxLength),
				sprintf('must be at most %J characters long', valueSpec.maxLength));
		}

		if (exists(valueSpec, 'minLength')) {
			this.emit_test_expression(indent + '\t',
				sprintf('length(%s) < %J', valueExpr, valueSpec.minLength),
				sprintf('must be at least %J characters long', valueSpec.minLength));
		}

		if (exists(valueSpec, 'format')) {
			if (exists(this.format_validators, valueSpec.format)) {
				this.emit_test_expression(indent + '\t',
					sprintf('!%s(%s)', to_method_name('match', valueSpec.format), valueExpr),
					sprintf('must be a valid %s', this.format_validators[valueSpec.format].desc));
			}
			else {
				warn("Unrecognized string format '" + valueSpec.format + '".\n');
			}
		}

		this.print(indent, '}\n');
	},

	emit_array_tests: function(indent, valueExpr, valueSpec)
	{
		if (!this.has_type_keywords('array', valueSpec))
			return;

		this.print(indent, 'if (type(%s) == "array") {', valueExpr);

		if (exists(valueSpec, 'maxItems')) {
			this.emit_test_expression(indent + '\t',
				sprintf('length(%s) > %J', valueExpr, valueSpec.maxItems),
				sprintf('must not have more than %J items', valueSpec.maxItems));
		}

		if (exists(valueSpec, 'minItems')) {
			this.emit_test_expression(indent + '\t',
				sprintf('length(%s) < %J', valueExpr, valueSpec.minItems),
				sprintf('must have at least %J items', valueSpec.minItems));
		}

		/* XXX: uniqueItems, maxContains, minContains */

		let itemSpec = valueSpec.items,
		    isRef = this.is_ref(itemSpec);

		if (type(itemSpec) == "object") {
			if (isRef) {
				this.print(indent, '	return map(value, (item, i) => %s(location + "/" + i, item, errors));',
					to_method_name('instantiate', replace(isRef, '#/$defs/', '')));
			}
			else {
				this.emit_spec_validation_function(indent + '\t', 'parse', 'item', itemSpec);
				this.print(indent, '	return map(value, (item, i) => parseItem(location + "/" + i, item, errors));');
			}
		}

		this.print(indent, '}\n');
	},

	emit_object_tests: function(indent, valueExpr, valueSpec)
	{
		if (!this.has_type_keywords('object', valueSpec))
			return;

		this.print(indent, 'if (type(%s) == "object") {', valueExpr);

		if (exists(valueSpec, 'maxProperties')) {
			this.emit_test_expression(indent + '\t',
				sprintf('length(%s) > %J', valueExpr, valueSpec.maxProperties),
				sprintf('must have at most %J properties', valueSpec.maxProperties));
		}

		if (exists(valueSpec, 'minProperties')) {
			this.emit_test_expression(inden + '\t',
				sprintf('length(%s) < %J', valueExpr, valueSpec.minProperties),
				sprintf('must have at least %J properties', valueSpec.minProperties));
		}

		if (type(valueSpec.propertyNames) == "object") {
			let keySpec = { type: 'string', ...(valueSpec.propertyNames) };

			this.print(indent, '	for (let propertyName in value) {');
			this.emit_spec_validation_tests(indent + '\t\t', 'propertyName', keySpec);
			this.print(indent, '	}');
			this.print(indent, '');
		}

		if (exists(valueSpec, "$ref")) {
			let fn = to_method_name('instantiate', replace(valueSpec['$ref'], '#/$defs/', ''));

			if (valueSpec.additionalProperties === true)
				this.print(indent, '	let obj = { ...value, ...(%s(location, value, errors)) };\n', fn);
			else
				this.print(indent, '	let obj = %s(location, value, errors);\n', fn);
		}
		else {
			if (valueSpec.additionalProperties === true)
				this.print(indent, '	let obj = { ...value };\n');
			else
				this.print(indent, '	let obj = {};\n');
		}

		if (type(valueSpec.properties) == "object") {
			for (let objectPropertyName, propertySpec in valueSpec.properties) {
				let valueExpr = sprintf('value[%J]', objectPropertyName),
				    isRef = this.is_ref(propertySpec);

				if (!isRef) {
					this.emit_spec_validation_function(
						indent + '\t',
						'parse',
						objectPropertyName,
						propertySpec);
				}

				this.print(indent, '	if (exists(value, %J)) {',
					objectPropertyName);

				if (isRef) {
					this.print(indent, '		obj.%s = %s(location + "/%s", %s, errors);',
						to_property_name(objectPropertyName),
						to_method_name('instantiate', replace(isRef, '#/$defs/', '')),
						to_json_ptr(objectPropertyName),
						valueExpr);
				}
				else {
					this.print(indent, '		obj.%s = %s(location + "/%s", %s, errors);',
						to_property_name(objectPropertyName),
						to_method_name('parse', objectPropertyName),
						to_json_ptr(objectPropertyName),
						valueExpr);
				}

				this.print(indent, '	}');

				if (exists(propertySpec, 'default')) {
					this.print(indent, '	else {');

					this.print(indent, '		obj.%s = %J;',
						to_property_name(objectPropertyName),
						propertySpec.default);

					this.print(indent, '	}');
				}
				else if (objectPropertyName in valueSpec.required) {
					this.print(indent, '	else {');
					this.print(indent, '		push(errors, [ location, "is required" ]);');
					this.print(indent, '	}');
				}

				this.print(indent, '');
			}
		}

		this.print(indent, '	return obj;');

		this.print(indent, '}\n');
	},

	read_schema: function(path)
	{
		let fd = fs.open(path, "r");

		if (!fd)
			return {};

		let schema = json(fd.read("all"));

		fd.close();

		return schema;
	},

	print: function(indent, fmt, ...args)
	{
		if (length(fmt)) {
			print(indent);
			printf(fmt, ...args);
		}

		print("\n");
	},

	emit_spec_validation_tests: function(indent, valueExpr, valueSpec)
	{
		let variantSpecs, variantErrorCond, variantErrorMsg;

		if (type(valueSpec.anyOf) == "array" && length(valueSpec.anyOf) > 0) {
			variantSpecs = valueSpec.anyOf;
			variantErrorCond = '== 0';
			variantErrorMsg = 'at least one';
		}
		else if (type(valueSpec.oneOf) == "array" && length(valueSpec.oneOf) > 0) {
			variantSpecs = valueSpec.oneOf;
			variantErrorCond = '!= 1';
			variantErrorMsg = 'exactly one';
		}
		else if (type(valueSpec.allOf) == "array" && length(valueSpec.allOf) > 0) {
			variantSpecs = valueSpec.allOf;
			variantErrorCond = sprintf('!= %d', length(variantSpecs));
			variantErrorMsg = 'all';
		}

		if (variantSpecs) {
			let functionNames = [];

			for (let i, subSpec in variantSpecs)
				push(functionNames, this.emit_spec_validation_function(indent, 'parseVariant', i, subSpec));

			this.print(indent, 'let success = 0, tryval, tryerr, vvalue = null, verrors = [];\n');

			for (let functionName in functionNames) {
				this.print(indent, 'tryerr = [];');
				this.print(indent, 'tryval = %s(location, value, tryerr);', functionName);
				this.print(indent, 'if (!length(tryerr)) {');
				this.print(indent, '	if (type(vvalue) == "object" && type(tryval) == "object")');
				this.print(indent, '		vvalue = { ...vvalue, ...tryval };');
				this.print(indent, '	else');
				this.print(indent, '		vvalue = tryval;\n');
				this.print(indent, '	success++;');
				this.print(indent, '}');
				this.print(indent, 'else {');
				this.print(indent, '	push(verrors, join(" and\\n", map(tryerr, err => "\\t - " + err[1])));');
				this.print(indent, '}\n');
			}

			this.print(indent, 'if (success %s) {', variantErrorCond);
			this.print(indent, '	if (length(verrors))');
			this.print(indent, '		push(errors, [ location, "must match %s of the following constraints:\\n" + join("\\n- or -\\n", verrors) ]);', variantErrorMsg);
			this.print(indent, '	else');
			this.print(indent, '		push(errors, [ location, "must match only one variant" ]);');
			this.print(indent, '	return null;');
			this.print(indent, '}\n');
			this.print(indent, 'value = vvalue;\n');
		}

		this.emit_number_tests(indent, valueExpr, valueSpec);
		this.emit_string_tests(indent, valueExpr, valueSpec);
		this.emit_array_tests(indent, valueExpr, valueSpec);
		this.emit_object_tests(indent, valueExpr, valueSpec);
		this.emit_generic_tests(indent, valueExpr, valueSpec);
	},

	emit_format_validation_function: function(indent, verb, formatName, formatCode)
	{
		let functionName = to_method_name(verb, formatName);

		this.print(indent, 'function %s(value) {', functionName);

		for (let line in formatCode)
			this.print(indent, '	' + line);

		this.print(indent, '}\n');
	},

	emit_spec_validation_function: function(indent, verb, propertyName, valueSpec)
	{
		let functionName = to_method_name(verb, propertyName),
		    isRef = this.is_ref(valueSpec);

		this.print(indent, 'function %s(location, value, errors) {', functionName);

		if (isRef) {
			this.print(indent, '	value = %s(location, value, errors);\n',
				to_method_name('instantiate', replace(isRef, '#/$defs/', '')));
		}

		this.emit_spec_validation_tests(indent + '\t', 'value', valueSpec);

		this.print(indent, '	return value;');
		this.print(indent, '}\n');

		return functionName;
	},

	generate: function()
	{
		let indent = '';

		this.schema = this.read_schema(this.path);

		this.print(indent, '// Automatically generated from %s - do not edit!', this.path);
		this.print(indent, '"use strict";\n');

		for (let formatName, formatCode in this.format_validators)
			this.emit_format_validation_function(indent, 'match', formatName, formatCode.code);

		for (let definitionId, definitionSpec in this.schema['$defs'])
			this.emit_spec_validation_function(indent, 'instantiate', definitionId, definitionSpec);

		this.emit_spec_validation_function(indent, 'new', "UCentralState", this.schema);

		this.print(indent, 'return {');
		this.print(indent, '	validate: (value, errors) => {');
		this.print(indent, '		let err = [];');
		this.print(indent, '		let res = newUCentralState("", value, err);');
		this.print(indent, '		if (errors) push(errors, ...map(err, e => "[E] (In " + e[0] + ") Value " + e[1]));');
		this.print(indent, '		return length(err) ? null : res;');
		this.print(indent, '	}');
		this.print(indent, '};');
	}
};

function instantiateGenerator(path) {
	return proto({ path }, GeneratorProto);
}

let generator = instantiateGenerator("./ucentral.schema.pretty.json");

generator.generate();
