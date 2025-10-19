import * as fs from 'fs';

export function generate_deltas(counters, prev_counters) {
	let ret = {};
	for (let k in [ "rx_packets", "tx_packets", "rx_bytes", "tx_bytes", "tx_retries", "tx_failed", "rx_errors", "tx_errors", "rx_dropped", "tx_dropped",  "multicast", "collisions" ]) {
		if (prev_counters[k] < 0)
			prev_counters[k] = 0;
		ret[k] = counters[k] - prev_counters[k];
		if (ret[k] < 0) {
			if (counters[k] > 0)
				ret[k] = counters[k];
			else
				ret[k] = 0;
		}
	}
	return ret;
};

export function ports_deltas(port, ports, previous) {
	if (!ports[port]?.counters || !previous.ports[port]?.counters)
		return {};

	return generate_deltas(ports[port].counters, previous.ports[port].counters);
};

export function stations_deltas(assoc, iface, previous) {
	let ret = {};
	// Search for the station in the dynamic iface
	if (assoc.dynamic_vlan)
		iface = iface + "-v" + assoc.dynamic_vlan;
	if (!previous.stations[iface] || !previous.stations[iface][assoc.station])
		return ret;
	for (let k in [ "rx_packets", "tx_packets", "rx_bytes", "tx_bytes", "tx_retries", "tx_failed" ]) {
		if (assoc["connected_time"] < previous.stations[iface][assoc.station]["connected_time"]) {
			ret[k] = assoc[k];
		} else {
			ret[k] = assoc[k] - (previous.stations[iface][assoc.station][k] || 0);
		}
		// Still negative?
		if (ret[k] < 0 && assoc[k] > 0) {
			ret[k] = assoc[k];
		} else if (ret[k] < 0) {
			ret[k] = 0;
		}
	}
	return ret;
};

export function load_previous_state() {
	return json(fs.readfile('/tmp/' + (global.telemetry ? 'telemetry.json' : 'state.json')) || '{ "ports": {}, "devstats": {}, "stations": {}, "devstats": {} }');
};

export function save_current_state(telemetry, data) {
	fs.writefile('/tmp/' + (telemetry ? 'telemetry.json' : 'state.json'), data);
};

