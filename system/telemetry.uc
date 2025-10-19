#!/usr/bin/ucode

let fs = require("fs");
let f = fs.open("/tmp/ucentral.telemetry", "w");
if (f)
	f.close();

global.telemetry = true;

include("state.uc");
