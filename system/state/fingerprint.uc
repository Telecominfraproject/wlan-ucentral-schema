import * as fs from 'fs';
import * as network_module from './network.uc';

let finger_config = global.uci.get_all("state", "fingerprint");
let finger_state = json(fs.readfile('/tmp/finger.state') || '{}');
let fingerprint;
let finger_wan = [];

if (finger_config?.mode != 'polled')
	fingerprint = global.ubus.call("fingerprint", "fingerprint", { age: +(finger_config?.min_age || 0), raw: (finger_config?.mode == 'raw') }) || {};


if (!+finger_config?.allow_wan) 
	for (let k in global.uci.get("event", "config", "wan_port"))
		push(finger_wan, network_module.lookup_port(k, global.select_ports));

let now = time();
if (fingerprint) {
	for (let mac in fingerprint) {
		if (!finger_state[mac])
			finger_state[mac] = { reported: 0 };
		finger_state[mac].seen = now;
	}

	for (let mac, data in finger_state)
		if ((now - data.seen) > (+finger_config?.max_age || 600))
			delete finger_state[mac];
}

export function get_fingerprint_for_mac(mac, ports) {
	if (finger_config?.mode != 'final')
		return null;
	if (!fingerprint[mac])
		return null;
	if (ports)
		for (let port in finger_wan)
			if (port in ports)
				return 0;
	if ((time() - finger_state[mac].reported || 0) < (+finger_config.period || 0))
		return null;
	finger_state[mac].reported = time();
	return fingerprint[mac];
};

export function save_state(state) {
	if (fingerprint) {
		switch(finger_config?.mode) {
		case 'raw-data':
			state.fingerprint = fingerprint;
			break;
		case 'final':
			fs.writefile('/tmp/finger.state', finger_state);
			break;
		}
	}
};
