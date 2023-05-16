#!/usr/bin/ucode
let fs = require('fs');
let pmsg = fs.open('/dev/pmsg0', 'w');
pmsg.write({ boot_cause: reason ? reason : ARGV[0] });
pmsg.close();
