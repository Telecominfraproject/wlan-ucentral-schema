let uloop = require('uloop');
let fs = require('fs');
let result;
let abort;
let signature = require('signature');
if (args.type == 'diagnostic') {
	system('cp /usr/share/ucentral/diagnostic.uc /tmp/script.cmd');
} else {
	let decoded = b64dec(args.script);
	if (!decoded) {
		result_json({
			"error": 2,
			"result": "invalid base64"
		});
		return;
	}

	let script = fs.open("/tmp/script.cmd", "w");
	script.write(decoded);
	script.close();
	fs.chmod("/tmp/script.cmd", 700);
}

if (args.type != 'diagnostic' &&
    restrict.commands &&
    !signature.verify("/tmp/script.cmd", args.signature)) {
	result_json({
		"error": 3,
		"result": "invalid signature"
	});
	return;
}

let out = '';
if (args.uri) {
	result_json({ error: 0, result: 'pending'});
	out = `/tmp/bundle.${id}.tar.gz`;
}

uloop.init();

let t = uloop.task(
        function(pipe) {
		switch (args.type) {
		case 'diagnostic':
		case 'bundle':
			let bundle = require('bundle');
			bundle.init(id);
			try {
				include('/tmp/script.cmd', { bundle });
			} catch(e) {
				//e.stacktrace[0].context
			};
			bundle.complete();
			return;
		default:
			let stdout = fs.popen("/tmp/script.cmd " + out);
			let result = stdout.read("all");
			let error = stdout.close();
			return { result, error };
		}
        },

        function(res) {
                result = res;        
                uloop.end();
        }
);
if (args.timeout)
        uloop.timer(args.timeout * 1000, function() {
                t.kill();
                uloop.end();
                abort = true;
        });


uloop.run();

if (abort)
        result = {
                "error": 255,
                "result": "timed out"
        };

if (args.uri && !fs.stat(out)) {
	result_json({ error: 1,
		      result: 'script did not generate any output'});
} else if (args.uri) {
	ctx.call("ucentral", "upload", {file: out, uri: args.uri, uuid: args.serial});
	result_json({ error: 0,
		      result: 'done'});
} else
	result_json(result || { result: 255, error: 'unknown'});
