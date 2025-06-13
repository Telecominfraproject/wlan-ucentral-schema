let reset_cmdline = [ 'jffs2reset', '-r', '-y' ];

if (length(args) && args.keep_redirector) {
	let archive_cmdline = [
		'tar', 'czf', '/sysupgrade.tgz',
		"/etc/config/ucentral"
	];

	let files = [
			"/etc/ucentral/key.pem", "/etc/ucentral/cert.pem",
			"/etc/ucentral/gateway.json", "/etc/ucentral/profile.json",
			"/etc/ucentral/operational.pem", "/etc/ucentral/operational.ca",
			"/etc/ucentral/restrictions.json",
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

system("touch /ucentral.upgrade");
system("(sleep 10; " + join(' ', reset_cmdline) + ")&");
system("/etc/init.d/ucentral stop");
