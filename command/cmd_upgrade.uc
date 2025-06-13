let image_path = "/tmp/ucentral.upgrade";

function process_file(args, name, path) {
	if (!args[name]) {
		result(2, name + " is required in payload for secure download");
		return false;
	}
	let content = b64dec(args[name]);
	if (!content) {
		result(2, "Failed to base64 decode " + name);
		return false;
	}
	let f = fs.open(path, "w");
	if (!f) {
		result(2, "Failed to write " + name);
		return false;
	}
	f.write(content);
	f.close();

	return true;
}

function download_run(cmd) {
	let pipe = fs.popen(cmd);
	if (!pipe)
		return -1;

	let out = trim(pipe.read("all"));
	let ret = pipe.close();

	return { "err": ret, "http_code": int(out) };
}

if (!args.uri) {
	result(2, "No firmware URL provided");
	return;
}

let secure_download = true;
let ca_file   = "/etc/ucentral/operational.ca";
let cert_file = "/etc/ucentral/operational.pem";
let key_file =  "/etc/ucentral/key.pem";

if (args['use-local-certificates'] == null) {
    // Backwards compatibility: not provided by the cloud
	secure_download = false;
}
else if (args['use-local-certificates'] == false) {
	ca_file =   "/tmp/_upgrade_cas.pem";
	cert_file = "/tmp/_upgrade_cert.pem";
	key_file =  "/tmp/_upgrade_key.pem";

	if (!process_file(args, "ca-certificate", ca_file))
		return;
	if (!process_file(args, "certificate", cert_file))
		return;
	if (!process_file(args, "private-key", key_file))
		return;
}

let sargs = "";
if (secure_download) {
	sargs = `--cacert ${ca_file} --cert ${cert_file} --key ${key_file}`;
}

let dl_cmd = `curl ${sargs} -w "%{http_code}" -o ${image_path} "${args.uri}"`;
let dl_ret = download_run(dl_cmd);
if (dl_ret.err != 0 || dl_ret.http_code < 200 || dl_ret.http_code >= 300) {
	// Try a second time before erroring out
	dl_ret = download_run(dl_cmd);
	if (dl_ret.err != 0 || dl_ret.http_code < 200 || dl_ret.http_code >= 300) {
		result(2, "Download failed, err %d, http_code %d, cmd %s", dl_ret.err, dl_ret.http_code, dl_cmd);
		return;
	}
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
		"/etc/ucentral/key.pem", "/etc/ucentral/cert.pem",
		"/etc/ucentral/gateway.json", "/etc/ucentral/profile.json",
		"/etc/ucentral/operational.pem", "/etc/ucentral/operational.ca",
		"/etc/ucentral/restrictions.json",
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
