log("Initiating reboot");

include('reboot_cause.uc', { reason: 'reboot' });

system("(sleep 10; reboot)&");
system("/etc/init.d/ucentral stop");

let err = ctx.error();

if (err != null)
	result(2, "Reboot call failed with status %s", err);
