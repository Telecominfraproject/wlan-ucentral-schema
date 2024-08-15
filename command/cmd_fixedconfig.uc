
if (!args.country) {
	result(2, 'Country code is missing.');
	return;
}

if (capab.country_code && !(args.country in capab.country_code)) {
	result(2, 'Country code "%s" is not allowed.', args.country);
	return;
}

if (fs.stat('/tmp/squashfs')) {
	system('fw_setenv country ' + args.country);
} else { 
	system('mount_certs');
	fs.writefile('/certificates/ucentral.defaults', args);
}
fs.writefile('/etc/modules.conf', 'options cfg80211 ieee80211_regdom=' + args.country);

include('reboot_cause.uc', { reason: 'fixedconfig' });
result(0, "Applied fixed config, rebooting");
sleep(5);
system('umount /certificates');
system('ubidetach -d 3');
system("(sleep 10; jffs2reset -r -y)&");
system("/etc/init.d/ucentral stop");
