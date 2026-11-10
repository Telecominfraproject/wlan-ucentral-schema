import * as fs from 'fs';
import * as network_module from './network.uc';

let finger_config = global.uci.get_all("state", "fingerprint");
let finger_state = json(fs.readfile('/tmp/finger.state') || '{}');
let fingerprint;
let finger_wan = [];

/*
 * Telemetry consumers do not read fingerprints, and this call is not cheap:
 * ufpd's fingerprint method refreshes its plugins inline, and plugin_mdns
 * retries with a blocking one second sleep while a handled mDNS service has
 * no host (2.02 s measured on a lab AP that sees an unresolved _ipp._tcp
 * service). Leave fingerprint unset on a telemetry run: that also stops
 * save_state() from writing /tmp/finger.state, and keeps the .reported
 * stamps for the periodic state message, which is the one the controller
 * reads client names from.
 *
 * Test the flag for truthiness rather than for false: this module body runs
 * while state.uc imports it, which happens before state.uc defaults
 * global.telemetry to false, so on a periodic run it is still unset here.
 */
if (!global.telemetry && finger_config?.mode != 'polled')
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
	/*
	 * A telemetry run gathered no fingerprint data, so there is nothing to
	 * index below, and stamping .reported here would hide the client's
	 * fingerprint from the periodic state message for up to
	 * state.fingerprint.period seconds.
	 */
	if (global.telemetry)
		return null;
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
		case 'raw':
			state.fingerprint = fingerprint;
			break;
		case 'final':
			fs.writefile('/tmp/finger.state', finger_state);
			break;
		}
	}
};
