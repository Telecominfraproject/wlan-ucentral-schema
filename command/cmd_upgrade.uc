let image_path = "/tmp/ucentral.upgrade";

if (!args.uri) {
	result(2, "No firmware URL provided");
	return;
}

let download_cmdline = [ 'wget', '-O', image_path, args.uri ];
let rc = system(download_cmdline);

if (rc != 0) {
	result(2, "Download command %s exited with non-zero code %d", download_cmdline, rc);

	return;
}

let validation_result = ctx.call("system", "validate_firmware_image", { path: image_path });

if (!validation_result) {
	result(2, "Validation call failed with status %s", ubus.error());

	return;
}
else if (!validation_result.valid) {
	result_json({
		"error": 2,
		"text": "Firmware image validation failed",
		"data": sprintf("Archive command %s exited with non-zero code %d", archive_cmdline, rc)
	});

	warn(sprintf("ucentral-upgrade: firmware file validation failed: %J\n", validation_result));

	return;
}

if (restrict.sysupgrade) {
	let signature = require('signature');
	if (!signature.verify(image_path, args.signature)) {
		result_json({
			"error": 2,
			"text": "Invalid signature",
			"resultCode": -1
		});

		return;
	}
}

let archive_cmdline = [
	'tar', 'czf', '/upgrade.tgz',
	'/etc/config/ucentral'
];

if (args.keep_redirector) {
	let files = [
		"/etc/ucentral/cas.pem", "/etc/ucentral/cert.pem",
		"/etc/ucentral/redirector.json", "/etc/ucentral/dev-id",
		"/etc/ucentral/key.pem", "/etc/ucentral/gateway.json",
		"/etc/ucentral/profile.json", "/etc/ucentral/restrictions.json",
	];
	for (let f in files)
		if (fs.stat(f))
			push(archive_cmdline, f);
}

if (args.keep_config) {
	let active_config = fs.readlink("/etc/ucentral/ucentral.active");

	if (active_config)
		push(archive_cmdline, '/etc/ucentral/ucentral.active', active_config);
	else
		result(2, "Unable to determine active configuration: %s", fs.error());
}

if (args.keep_redirector || args.keep_config) {
	let rc = system(archive_cmdline);

	if (rc != 0) {
		result(2, "Archive command %s exited with non-zero code %d", archive_cmdline, rc);

		return;
	}
}

include('reboot_cause.uc', { reason: 'upgrade' });
result(0, "Triggering FW upgrade");
sleep(2000);

let sysupgrade_cmdline = sprintf("sysupgrade %s %s",
				 (args.keep_redirector || args.keep_config) ? "-f /upgrade.tgz" : "-n",
				 image_path);

warn("Upgrading firmware\n");

system("touch /ucentral.upgrade");
system("(sleep 10; /etc/init.d/network stop; " + sysupgrade_cmdline + ")&");
system("/etc/init.d/ucentral stop");
