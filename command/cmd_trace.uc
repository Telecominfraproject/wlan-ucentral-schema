let serial = cursor.get("ucentral", "config", "serial");

if (!serial)
	return;

if (args.network) {
	let net = ctx.call("network.interface", "status", { interface: args.network });

	if (net && net.l3_device)
		args.interface = net.l3_device;
}

if (!args.interface || !length(args.interface))
	args.interface = args.network;

if (!match(args.interface, /^[^\/]+$/) || (args.interface != "any" && !fs.stat("/sys/class/net/" + args.interface))) {
	result_json({
		"error": 1,
		"text": "Failed",
		"resultCode": 1,
		"resultText": "Invalid network device specified"
	});

	return;
}

let duration = +args.duration || 0;
let packets = +args.packets || 0;
let filename = sprintf("/tmp/pcap-%s-%d", serial, time());
let sys = ctx.call('system', 'info');

let command =	[
	'tcpdump_timeout',
	duration,
	'-C', sys.memory.free / 4,
	'-W', '1',
	'-w', filename,
	'-i', args.interface
];

if (!duration) {
	push(command, '-c');
	push(command, packets);
}
let rc = system(command);

if (rc != 0) {
	result_json({
		"error": 1,
		"text": "Failed",
		"resultCode": rc,
		"resultText": "tcpdump command exited with non-zero code"
	});

	return;
}

ctx.call("ucentral", "upload", {file: filename, uri: args.uri, uuid: args.serial});

result_json({
	"error": 0,
	"text": "Success",
	"resultCode": 0,
	"resultText": "Uploading file"
});
