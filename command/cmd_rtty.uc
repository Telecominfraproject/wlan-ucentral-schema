if (!args.id || !args.server || !args.port || !args.token || !args.timeout) {
	result_json({
		"error": 2,
		"text": "Invalid parameters.",
		"resultCode": -1
	});

	return;
}

if (restrict.rtty) {
	result_json({
		"error": 2,
		"text": "RTTY is restricted.",
		"resultCode": -1
	});

	return;
}


cursor.load("rtty");
cursor.set("rtty", "@rtty[-1]", "enable", 1);
cursor.set("rtty", "@rtty[-1]", "id", args.id);
cursor.set("rtty", "@rtty[-1]", "host", args.server);
cursor.set("rtty", "@rtty[-1]", "port", args.port);
cursor.set("rtty", "@rtty[-1]", "token", args.token);
cursor.set("rtty", "@rtty[-1]", "timeout", args.timeout);
cursor.commit();

system("/etc/init.d/rtty restart");
result_json({
	"error": 0,
	"text": "Command was executed"
});
