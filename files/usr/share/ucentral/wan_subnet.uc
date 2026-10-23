#!/usr/bin/ucode
// SPDX-License-Identifier: BSD-3-Clause
"use strict";

// Maintain the upstream IPv4 subnet set (ucentral_wan4) for dynamic upstream
// subnet tracking and isolation. Writes the set definition
// with every IPv4 subnet of the active upstream (up*) interfaces to the file
// fw4 includes at table-pre, and, when the set is already loaded in fw4,
// replaces its elements in one nft transaction so it is never seen empty.

import * as fs from 'fs';
import { connect } from 'ubus';

const DIR = '/etc/ucentral';
const FILE = DIR + '/wan4.nft';
const SET = 'ucentral_wan4';

function log(msg) {
	system([ 'logger', '-t', 'ucentral-wan-subnet', msg ]);
}

// auto-merge: overlapping upstream subnets would otherwise make the
// definition, and with it the whole fw4 ruleset, fail to load.
function set_definition(subnets) {
	let def = 'set ' + SET + ' {\n\ttype ipv4_addr\n\tflags interval\n\tauto-merge\n';

	if (length(subnets))
		def += '\telements = { ' + join(', ', subnets) + ' }\n';

	return def + '}\n';
}

function write_if_changed(content) {
	if (fs.readfile(FILE) == content)
		return;

	// per-process temp name: a render-time run can overlap a hotplug run
	let tmp = FILE + '.' + fs.readlink('/proc/self');

	fs.mkdir(DIR);

	if (fs.writefile(tmp, content) != length(content) || !fs.rename(tmp, FILE)) {
		log('wan_subnet: writing ' + FILE + ' failed, keeping the previous file');
		fs.unlink(tmp);
	}
}

function subnet(address, mask) {
	let octets = iptoarr(address);

	if (length(octets) != 4 || type(mask) != 'int' || mask < 1 || mask > 32 || address == '0.0.0.0')
		return null;

	let net = [];

	for (let i = 0, bits = mask; i < 4; i++, bits -= 8)
		push(net, octets[i] & (bits >= 8 ? 255 : (bits <= 0 ? 0 : (0xff << (8 - bits)) & 0xff)));

	return arrtoip(net) + '/' + mask;
}

let dump = connect()?.call('network.interface', 'dump');

if (type(dump?.interface) != 'array') {
	log('wan_subnet: network.interface dump failed, keeping the previous set');
	// fw4 cannot load a ruleset whose rule references a missing set, so make
	// sure a (possibly empty) definition exists for the table-pre include.
	if (!fs.access(FILE))
		write_if_changed(set_definition([]));
	exit(1);
}

let subnets = [];

for (let iface in dump.interface) {
	if (!iface.up || !wildcard(iface.interface, 'up*'))
		continue;

	for (let addr in iface['ipv4-address']) {
		let net = subnet(addr.address, addr.mask);

		if (net && !(net in subnets))
			push(subnets, net);
	}
}

write_if_changed(set_definition(subnets));

if (system('nft list set inet fw4 ' + SET + ' >/dev/null 2>&1') == 0) {
	let cmd = 'flush set inet fw4 ' + SET + '\n';

	if (length(subnets))
		cmd += 'add element inet fw4 ' + SET + ' { ' + join(', ', subnets) + ' }\n';

	let nft = fs.popen('nft -f -', 'w');

	if (!nft || !nft.write(cmd) || nft.close() != 0)
		log('wan_subnet: nft update of ' + SET + ' failed');
}

exit(0);
