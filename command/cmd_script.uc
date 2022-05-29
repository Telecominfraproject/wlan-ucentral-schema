/*let args = {
        "type": "shell",
        "script": "echo foo\n sleep 10\n",
        "timeout": 2
};

let args = {
        "type": "ucode",
        "script": "printf('this is ucode')",
        "timeout": 20
};*/

let uloop = require('uloop');
let fs = require('fs');
let result;
let abort;

let script = fs.open("/tmp/script.cmd", "w");
switch (args.type) {
case "shell":
        script.write("#!/bin/sh\n");
        break;
case "ucode":
	script.write("#!/usr/bin/ucode\n");
        break;
}
script.write(args.script);
script.close();
fs.chmod("/tmp/script.cmd", 700);

uloop.init();

let t = uloop.task(
        function(pipe) {
                let stdout = fs.popen("/tmp/script.cmd");
                let result = stdout.read("all");
                let error = stdout.close();
                return { result, error };
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

printf("%.J\n", result);
result_json(result);
