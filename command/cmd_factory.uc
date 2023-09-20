let reset_cmdline = [ 'jffs2reset', '-r', '-y' ];

if (length(args) && args.keep_redirector) {
	let archive_cmdline = [
		'tar', 'czf', '/sysupgrade.tgz',
		"/etc/config/ucentral"
	];

	let files = [
			"/etc/ucentral/cas.pem", "/etc/ucentral/cert.pem",
			"/etc/ucentral/gateway.json", "/etc/ucentral/dev-id",
			"/etc/ucentral/key.pem", "/etc/ucentral/profile.json"
	];
	for (let f in files)
		if (fs.stat(f))
			push(archive_cmdline, f);

	let active_config = fs.readlink("/etc/ucentral/ucentral.active");

	if (active_config)
		push(archive_cmdline, '/etc/ucentral/ucentral.active', active_config);
	else
		result_json({
			"error": 2,
			"text": sprintf("Unable to determine active configuration: %s", fs.error())
		});

	let rc = system(archive_cmdline);

	if (rc != 0) {
		result_json({
			"error": 2,
			"text": sprintf("Archive command %s exited with non-zero code %d", archive_cmdline, rc)
		});

		return;
	}

	push(reset_cmdline, '-k');
}

include('reboot_cause.uc', { reason: 'factory' });

let rc = system(reset_cmdline);

if (rc != 0)
	result_json({
		"error": 2,
		"text": sprintf("Reset command %s exited with non-zero code %d", reset_cmdline, rc)
	});
