#!/usr/bin/ucode
push(REQUIRE_SEARCH_PATH,
	"/usr/lib/ucode/*.so",
	"/usr/share/ucentral/*.uc");

let schemareader = require("schemareader");
let renderer = require("renderer");
let fs = require("fs");

let inputfile = fs.open(ARGV[0], "r");
let inputjson = json(inputfile.read("all"));
let custom_config = (split(ARGV[0], ".")[0] != "/etc/ucentral/ucentral");

let error = 0;

inputfile.close();
let logs = [];

function set_service_state(state) {
	for (let service, enable in renderer.services_state()) {
		if (enable != state)
			continue;
		printf("%s %s\n", service, enable ? "starting" : "stopping");
		system(sprintf("/etc/init.d/%s %s", service, enable ? "restart" : "stop"));
	}
	system("/etc/init.d/ucentral-wifi restart");
	system("/etc/init.d/dnsmasq restart");
}

try {
	for (let cmd in [ 'rm -rf /tmp/ucentral',
			  'mkdir /tmp/ucentral',
			  'rm /tmp/dnsmasq.conf',
			  '/etc/init.d/uhealth stop',
			  'touch /tmp/ucentral.health',
			  'touch /tmp/dnsmasq.conf' ])
		system(cmd);

	let state = schemareader.validate(inputjson, logs);

	let batch = state ? renderer.render(state, logs) : "";

	fs.stdout.write("Log messages:\n" + join("\n", logs) + "\n\n");

	fs.stdout.write("UCI batch output:\n" + batch + "\n");

	if (state) {
		let outputjson = fs.open("/tmp/ucentral.uci", "w");
		outputjson.write(batch);
		outputjson.close();

		for (let cmd in [ 'rm -rf /tmp/config-shadow',
				  'cp -r /etc/config-shadow /tmp' ])
			system(cmd);

		let apply = fs.popen("/sbin/uci -c /tmp/config-shadow batch", "w");
		apply.write(batch);
		apply.close();

		renderer.write_files(logs);

		set_service_state(false);

		for (let cmd in [ 'uci -c /tmp/config-shadow commit',
				  'cp /tmp/config-shadow/* /etc/config/',
				  'rm -rf /tmp/config-shadow',
				  'wifi',
				  'reload_config',
				  '/etc/init.d/dnsmasq restart'])
			system(cmd);

		if (!custom_config) {
			fs.unlink('/etc/ucentral/ucentral.active');
			fs.symlink(ARGV[0], '/etc/ucentral/ucentral.active');
		}

		set_service_state(true);
	} else {
		error = 1;
	}
	if (!length(batch))
		error = 2;
	else if (length(logs))
		error = 1;
}
catch (e) {
	error = 2;
	warn("Fatal error while generating UCI: ", e, "\n", e.stacktrace[0].context, "\n");
}

let ubus = require("ubus").connect();

if (inputjson.uuid && inputjson.uuid > 1 && !custom_config) {
	let status = {
		error,
		text: error ? "Failed" : "Success",
	};
	if (length(logs))
		status.rejected = logs;

	ubus.call("ucentral", "result", {
		uuid: inputjson.uuid || 0,
		id: +ARGV[1] || 0,
		status,
	});
}
