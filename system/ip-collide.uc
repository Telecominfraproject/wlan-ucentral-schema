#!/usr/bin/ucode

import * as libuci from 'uci';
import * as libubus from 'ubus';
import { ulog, LOG_INFO, LOG_ERR, LOG_WARNING } from 'log';
import { ipcalc } from 'libs.ipcalc';

let uci = libuci.cursor();
let ubus = libubus.connect();
let status = ubus.call("network.interface", "dump");
let up = [];
let down = [];
let collision = false;


uci.load("network");

for (let iface in status.interface) {
	if (!iface.up || !length(iface['ipv4-address']))
		continue;
	let role = split(iface.device, /[[:digit:]]/);
	switch (role[0]) {
	case 'up':
		push(up, iface);
		break;
	case 'down':
		push(down, iface);
		break;
	}
}

for (let iface in up)
	for (let addr in iface['ipv4-address'])
		ipcalc.reserve_prefix(iptoarr(addr.address), addr.mask);

for (let iface in down)
	for (let addr in iface['ipv4-address'])
		if (!ipcalc.reserve_prefix(iptoarr(addr.address), addr.mask)) {
			let auto = ipcalc.generate_prefix_simple('192.168.0.0/16', sprintf('auto/%d', addr.mask));
			ulog(LOG_WARNING, 'ip-collide: collision detected on %s', iface.device);
			if (auto) {
				ulog(LOG_INFO, 'ip-collide: moving from %s/%d to %s', addr.address, addr.mask, auto);
				uci.set('network', iface.device, 'ipaddr', auto);
			} else {
				ulog(LOG_ERR, 'ip-collide: no free address available, shutting down device');
				system(sprintf('ifconfig %s down', iface.device));
			}
			uci.set('network', iface.device, 'collision', time());
			collision = true;
		}

if (collision) {
	uci.commit();
	system('reload_config');
}
