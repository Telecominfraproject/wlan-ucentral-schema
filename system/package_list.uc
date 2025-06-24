#!/usr/bin/ucode

let fs = require("fs");

let package_json = [];

let fd = fs.open("/tmp/packages.state");
if (fd) {
    let line;
    while (line = fd.read("line")) {
        let tokens = split(line, " - ");

        if (length(tokens) < 2) {
            continue;
        }

        push(package_json, {"name": tokens[0], "version": replace(tokens[1], "\n", "")});
    }
    fd.close();
}

fs.writefile('/tmp/packages.json', {"packages": package_json});
