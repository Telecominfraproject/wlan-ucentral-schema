#!/usr/bin/ucode

import * as fs from 'fs';

let package_json = [];

let fd = fs.open("/tmp/packages.state", "r");
if (fd) {
    let line;
    while (line = fd.read("line")) {
        let pkg = split(trim(line), " ")[0];
        if (!pkg)
            continue;

        let m = match(pkg, /^(.+)-(\d.*)$/);
        if (!m)
            continue;

        push(package_json, {"name": m[1], "version": m[2]});
    }
    fd.close();
}

fs.writefile('/tmp/packages.json', {"packages": package_json});
