log("Initiating gateway transfer");

if (!args.server || !args.port) {
	result(2, "invalid arguments");
	return;
}

fs.writefile('/etc/ucentral/gateway.json', { server: args.server, port: args.port });
system('cp /etc/ucentral/ucentral.cfg.0000000001 /etc/ucentral/ucentral.cfg.0000000002');
system('rm /etc/ucentral/ucentral.cfg.1* /etc/ucentral/ucentral.active');

include('reboot_cause.uc', { reason: 'transfer' });

system("(sleep 10; reboot)&");
system("/etc/init.d/ucentral stop");

let err = ctx.error();

if (err != null)
	result(2, "Reboot call failed with status %s", err);
