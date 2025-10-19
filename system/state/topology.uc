import * as fs from 'fs';
import * as network_module from './network.uc';
import * as telemetry_module from './telemetry.uc';

export function sysfs_net(iface, prop) {
	let f = fs.open(sprintf("/sys/class/net/%s/%s", iface, prop), "r");
	let val = 0;

	if (f) {
		val = replace(f.read("all"), '\n', '');
		f.close();
	}
	if (val === null)
		val = 0;
	return val;
};

export function link_state_name(name) {
	let names = {
		'wan': 'upstream',
		'lan': 'downstream'
	};
	return names[name] || name;
};

export function get_vlan_id_for_port(sw_port, switch_name) {
	let current_vlan;
	let swconfig_cmd = "swconfig dev " + switch_name + " show";
	let sw_status = fs.popen(swconfig_cmd);

	for (let line; (line = sw_status.read("line")) != null; ){
		line = trim(line);

		let vlan_info = match(line, /^VLAN\s+(\d+):$/);
		if (vlan_info) {
			current_vlan = vlan_info[1];
			continue;
		}

		let port_info = match(line, /^ports:\s+(.+)$/);
		if (port_info && current_vlan) {
			let ports = split(port_info[1], /\s+/);

			for (let port_num in ports) {
				if (port_num == sw_port) {
					sw_status.close();
					return current_vlan;
				}
			}
		}
	}

	sw_status.close();
	return null;
};

export function get_sw_port_status(sw_port, switch_name, prop) {
	let speed_regexp, duplex_regexp, val;

	let swconfig_cmd = "swconfig dev " + switch_name + " port " + sw_port + " show";
	let sw_status = fs.popen(swconfig_cmd);

	for (let line; (line = sw_status.read("line")) != null; ){
		line = trim(line);

		switch (prop) {
			case 'carrier':
				if (match(line, /link:up/))
					val = 1;
				else if (match(line, /link:down/))
					val = 0;
				break;
			case 'speed':
				speed_regexp = match(line, /speed:([0-9]+)/);
				if (speed_regexp)
					val = speed_regexp[1];
				break;
			case 'duplex':
				duplex_regexp = match(line, /(full|half)-duplex/);
				if (duplex_regexp)
					val = duplex_regexp[1];
				break;
		}
	}

	sw_status.close();
	return val;
};

export function collect_link_state(state) {
	if (!length(global.capab.network))
		return;
	
	
	let link = {};
	let vlan_id;

	for (let name, net in global.capab.network) {
		let link_name = link_state_name(name);
		link[link_name] = {};

		for (let iface in global.capab.network[name]) {
			let port_state = {};
			let port_name = network_module.lookup_port(iface, global.select_ports);

			port_state.carrier = +sysfs_net(iface, "carrier");
			if (port_state.carrier) {
				port_state.speed = +sysfs_net(iface, "speed");
				port_state.duplex = sysfs_net(iface, "duplex");
			}

			if (length(global.capab.switch_ports)) {
				for (let eth_port, sw_port_info in global.capab.switch_ports) {
					let sw_iface = split(iface, ":");
					if (sw_iface[0] == eth_port) {
						vlan_id = get_vlan_id_for_port(sw_iface[1], sw_port_info['name']);

						if (vlan_id) {
							iface = eth_port + "." + vlan_id;
						}

						port_state.carrier = get_sw_port_status(sw_iface[1], sw_port_info['name'], "carrier");
						if (port_state.carrier) {
							port_state.speed = get_sw_port_status(sw_iface[1], sw_port_info['name'], "speed");
							port_state.duplex = get_sw_port_status(sw_iface[1], sw_port_info['name'], "duplex");
						}
					}
				}
			}

			if (global.ports && global.ports[iface].counters) {
				port_state.counters = global.ports[iface].counters;
				port_state.delta_counters = telemetry_module.ports_deltas(iface, global.ports, global.previous);
			}
			link[link_name][port_name] = port_state;
		}
	}
	
	if (length(link))
		state["link-state"] = link;
};

