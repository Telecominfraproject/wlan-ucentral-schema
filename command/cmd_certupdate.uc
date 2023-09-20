let tar = b64dec(args.certificates);

if (!tar || !fs.writefile('/tmp/certs.tar', tar)) {
	result_json({
		"error": 2,
		"text": 'failed to extract certificates'
	});
	return;
}

if (system('/sbin/certupdate')) {
	result_json({
		"error": 2,
		"text": 'failed to update certificates'
	});
	return;
}

include('reboot_cause.uc', { reason: 'certupdate' });

ctx.call("ucentral", "result", {
                "status": {
                        "error": 0,
                        "text": 'Success'
                }, "id": +id
        });
sleep(5000);
system("(sleep 10; jffs2reset -y -r)&");
system("/etc/init.d/ucentral stop");
