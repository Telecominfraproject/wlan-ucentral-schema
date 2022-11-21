#!/usr/bin/ucode
push(REQUIRE_SEARCH_PATH, '/usr/share/ucentral/*.uc');
let fs = require("fs");
let uci = require("uci");
let ubus = require("ubus");
let capabfile = fs.open("/etc/ucentral/capabilities.json", "r");
let capab = json(capabfile.read("all"));
let pipe = fs.popen('fw_printenv developer');
let developer = replace(pipe.read("all"), '\n', '');
pipe.close();
let restrict = {};
if (developer != 'developer=1') {
	let restrictfile = fs.open("/etc/ucentral/restrictions.json", "r");
	restrict = restrictfile ? json(restrictfile.read("all")) : {};
}
let cmdfile = fs.open(ARGV[0], "r");
let cmd = json(cmdfile.read("all"));
let id = ARGV[1];
let ctx = ubus.connect();

if (!ctx) {
	warn("Unable to connect to ubus: " + ubus.error() + "\n");
	exit(1);
}

/* Convenience logger outputting to both stderr and remote central log */
function log(fmt, ...args) {
	let msg = sprintf(fmt, ...args);

	warn(msg + "\n");

	ctx.call("ucentral", "log", { msg: msg });
}

function result(code, fmt, ...args) {
	let text = sprintf(fmt, ...args);

	ctx.call("ucentral", "result", {
		"status": {
			"error": code,
			"text": text
		}, "id": +id
	});
	warn(text + "\n");
}

function result_json(status) {
	ctx.call("ucentral", "result", {"id": +id, "status": status});
	if (status.text)
		warn(status.text + "\n");
	if (status.resultText)
		warn(status.resultText + "\n");
}

/* Scope of functions and ressources the command includes have access to */
let scope = {
	/* ressources */
	uci,
	cursor: uci.cursor(),
	ctx,
	fs,
	restrict,

	/* log helper */
	log,

	/* result helpers */
	result,
	result_json,

	/* command argument object */
	args: (cmd.payload || {}),

	/* cmd id */
	id: (id || 0)
};

if (match(cmd.command, /^[A-Za-z0-9_]+$/)) {
	try {
		include(sprintf("cmd_%s.uc", cmd.command), scope);
	}
	catch (e) {
		log("Exception invoking '%s' command module: %s\n%s\n",
			cmd.cmd, e, e.stacktrace[0].context);
	}
}
else {
	log("Invalid command module name specified");
}

