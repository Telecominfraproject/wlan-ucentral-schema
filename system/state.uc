#!/usr/bin/ucode

push(REQUIRE_SEARCH_PATH, '/usr/share/ucentral/*.uc');

import * as libuci from 'uci';
import * as libubus from 'ubus';
global.uci = libuci.cursor();
global.ubus = libubus.connect();

import * as fs from 'fs';
let cfgfile = fs.open("/etc/ucentral/ucentral.active", "r");
let cfg = json(cfgfile.read("all"));
let capabfile = fs.open("/etc/ucentral/capabilities.json", "r");
global.capab = json(capabfile.read("all"));

import * as system_module from 'state/system.uc';
import * as network_module from 'state/network.uc';
import * as topology_module from 'state/topology.uc';
import * as lldp_module from 'state/lldp.uc';
import * as telemetry_module from 'state/telemetry.uc';
import * as wifi_module from 'state/wifi.uc';
import * as fingerprint_module from 'state/fingerprint.uc';
import * as poe_module from 'state/poe.uc';
import * as gps_module from 'state/gps.uc';
import * as captive_module from 'state/captive.uc';
import * as ieee8021x_module from 'state/ieee8021x.uc';
import * as interfaces_module from 'state/interfaces.uc';
import * as topology_port_module from 'state/topology-port.uc';
import * as topology_mac_module from 'state/topology-mac.uc';

global.uci.load("state");
global.uci.load("event");

/* set up basic functionality */
global.telemetry ??= false;
global.delta = !global.telemetry;

let state = {
	version: 1,
	unit: {},
	interfaces: []
};

/* Helper function to safely execute and assign global data */
function safe_global_assign(name, fn, default_value) {
	try {
		let result = fn();
		return result ?? default_value;
	} catch (e) {
		state.exceptions ??= {};
		state.exceptions[name] = {
			message: e.message,
			stacktrace: e.stacktrace
		};
		return default_value;
	}
}

/* Gather global data with error handling */
global.stats = safe_global_assign("stats", () => global.uci.get_all("state", "stats"), {});
global.tid_stats = (index(global.stats.types, 'tid-stats') > 0);
global.select_ports = safe_global_assign("select_ports", () => network_module.discover_ports(), {});
global.ports = safe_global_assign("ports", () => topology_port_module.getTopologyInfo(), {});
global.devstats = safe_global_assign("devstats", () => global.ubus.call('udevstats', 'dump'), {});
global.devices = safe_global_assign("devices", () => global.ubus.call("network.device", "status"), {});
global.snoop = safe_global_assign("snoop", () => global.ubus.call("dhcpsnoop", "dump"), {});
global.previous = safe_global_assign("previous", () => telemetry_module.load_previous_state(), { ports: {}, devstats: {}, stations: {} });
global.wireless = safe_global_assign("wireless", () => global.uci.get_all("wireless"), {});
global.ip4leases = safe_global_assign("ip4leases", () => network_module.prepare_dhcp_leases(), {});
global.dyn_vlans = safe_global_assign("dyn_vlans", () => network_module.get_dynamic_vlans(), {});
global.topology_mac = safe_global_assign("topology_mac", () => topology_mac_module.getTopologyMacInfo(), {});

/* Define module collection functions in order */
let modules = [
	{ name: "system", fn: system_module.collect },
	{ name: "wifi_radios", fn: wifi_module.collect_wifi_radios },
	{ name: "interfaces", fn: interfaces_module.collect },
	{ name: "wifi_dynamic_vlans", fn: wifi_module.collect_dynamic_vlans },
	{ name: "poe", fn: poe_module.collect },
	{ name: "topology", fn: topology_module.collect_link_state },
	{ name: "lldp", fn: lldp_module.collect_lldp_peers },
	{ name: "ieee8021x", fn: ieee8021x_module.collect },
	{ name: "fingerprint", fn: fingerprint_module.save_state },
	{ name: "gps", fn: gps_module.collect },
	{ name: "captive", fn: captive_module.collect }
];

/* Execute each module with error handling */
for (let module in modules) {
	try {
		module.fn(state);
	} catch (e) {
		state.exceptions ??= {};
		state.exceptions[module.name] = {
			message: e.message,
			stacktrace: e.stacktrace
		};
	}
}

printf("%.J\n", state);

let msg = {
	uuid: cfg.uuid || 1,
	serial: global.uci.get("ucentral", "config", "serial"),
	state
};

if (global.telemetry) {
	global.ubus.call("ucentral", "telemetry", { "event": "state", "payload": msg });
	let f = fs.open("/tmp/ucentral.telemetry", "w");
	if (f) {
		f.write(msg);
		f.close();
	}
	return;
}

global.ubus.call("ucentral", "stats", msg);
let f = fs.open("/tmp/ucentral.state", "w");
if (f) {
	f.write(msg);
	f.close();
}
else {
	printf("Unable to open %s for writing: %s", statefile_path, fs.error());
}
