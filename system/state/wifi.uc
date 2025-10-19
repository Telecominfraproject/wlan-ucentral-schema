import * as fs from 'fs';
import * as halow_module from './halow.uc';
import * as telemetry_module from './telemetry.uc';
import * as fingerprint_module from './fingerprint.uc';

/* Load WiFi data via require */
let wifiphy = require('wifi.phy');
let wifiiface = require('wifi.iface');
let stations = require('wifi.station');
let survey = require('wifi.survey');
let mesh = require('wifi.mesh');

/* Collect data via ubus */
let wifistatus = global.ubus.call("network.wireless", "status");

/* Discover WDS STA dynamic interfaces (e.g., wlan2.sta1) */
function discover_wds_interfaces() {
	let wds_interfaces = [];

	for (let radio, data in wifistatus) {
		for (let k, vap in data.interfaces) {
			let base_ifname = vap.ifname;
			let wds_pattern = "/sys/class/net/" + base_ifname + ".sta*";
			let wds_paths = fs.glob(wds_pattern);

			for (let wds_path in wds_paths) {
				let wds_ifname = split(wds_path, "/")[-1];
				push(wds_interfaces, wds_ifname);
			}
		}
	}

	return wds_interfaces;
}

/* Collect stations from both regular and WDS interfaces */
function collect_all_stations() {
	let all_stations = { ...stations };
	let wds_interfaces = discover_wds_interfaces();

	for (let wds_ifname in wds_interfaces) {
		try {
			let wds_stations = global.ubus.call("hostapd." + wds_ifname, "get_clients");
			if (wds_stations && length(wds_stations))
				all_stations[wds_ifname] = wds_stations;
		} catch (e) {
			// WDS interface has no clients or hostapd call failed
		}
	}

	return all_stations;
}

let all_stations = collect_all_stations();

// Set up stations lookup for other modules
let stations_lookup = {};
for (let k, v in all_stations) {
	stations_lookup[k] = {};
	for (let assoc in v)
		stations_lookup[k][assoc.station] = assoc;
}


export function is_mesh(net, wif) {
	if (!net.batman)
		return false;
	if (wif.mode != 'mesh')
		return false;
	return true;
};


export function collect_wifi_radios(state) {
	let radios = [];
	
	for (let radio, data in wifistatus) {
		if (!length(data.interfaces))
			continue;
		let vap = wifiiface[data.interfaces[0].ifname];
		if (!length(vap))
			continue;

		let radio = {};
		radio.channel = vap.channel[0];
		radio.channels = uniq(vap.channel);
		radio.frequency = uniq(vap.frequency);
		radio.channel_width = +vap.ch_width;
		radio.tx_power = vap.tx_power;

		let path = data.config.path;
		if (exists(data.config, 'radio'))
			path += ':' + uc(data.config.band);
		radio.phy = path;
		if (wifiphy[path] && wifiphy[path].temperature)
			radio.temperature = wifiphy[path].temperature;
		radio.band = wifiphy[path].band;

		radio.chanUtil = 0;
		let radio_band = lc(radio.band[0]);
		let _chanUtil = int(fs.readfile('/tmp/chanutil_phy' + radio_band) || 0);
		if (_chanUtil > 0)
			radio.chanUtil = _chanUtil;

		// Check if this is a HaLow device and process accordingly
		if (!halow_module.process_halow_radio(radio, survey)) {
			// Non-HaLow device, process survey normally
			radio.survey = [];
			for (let k, v in survey.survey)
				if (v.frequency in radio.frequency)
					push(radio.survey, v);
		}
		delete radio.in_use;
		push(radios, radio);
	}
	
	if (length(radios))
		state.radios = radios;
	
	telemetry_module.save_current_state(global.telemetry, { ports: global.ports, devstats: global.devstats, stations: stations_lookup });
};

export function collect_wifi_ssids(iface) {
	if (index(global.stats.types, 'ssids') < 0 || !length(wifistatus))
		return [];
	
	let ssids = [];
	let counter = 0;

	for (let radio, data in wifistatus) {
		for (let k, vap in data.interfaces) {
			if (!length(vap.config) ||
			    !length(vap.config.network) ||
			    !wifiiface[vap.ifname])
				continue;
			let wif = wifiiface[vap.ifname];
			if (!(iface.name in vap.config.network) && !is_mesh(iface, wif))
				continue;
			let ssid = {
				radio:{"$ref": sprintf("#/radios/%d", counter)},
				phy: data.config.path,
				band: uc(data.config.band)
			};
			ssid.location = global.wireless[vap.section]?.ucentral_path || '';
			ssid.ssid = wif.ssid || vap.config.mesh_id;
			ssid.mode = wif.mode;
			ssid.bssid = wif.bssid;
			ssid.frequency = uniq(wif.frequency);
			for (let k, v in all_stations) {
				let vlan = split(k, '-v');
				let wds = split(k, '.sta');

				// Handle regular VAP interfaces (including VLAN tagged)
				if (vlan[0] == vap.ifname) {
					if (vlan[1])
						for (let k, assoc in v)
							assoc.dynamic_vlan = +vlan[1];
					ssid.associations = [ ...(ssid.associations || []), ...v ];
				}
				// Handle WDS STA interfaces (e.g., wlan2.sta1)
				else if (wds[0] == vap.ifname && wds[1]) {
					for (let assoc in v) {
						assoc.wds_interface = k;
						assoc.connection_type = "WDS-STA";
					}
					ssid.associations = [ ...(ssid.associations || []), ...v ];
				}
			}
			for (let assoc in ssid.associations) {
				let fp = fingerprint_module.get_fingerprint_for_mac(assoc.station, null);
				if (fp)
					assoc.fingerprint = fp;
				if (length(global.ip4leases[assoc.station]))
					assoc.ipaddr_v4 = global.ip4leases[assoc.station];
				else if (global.snoop && global.snoop[assoc.station]) {
					assoc.ipaddr_v4 = global.snoop[assoc.station];
					if (!(assoc.station in global.macs)) {
						if (!iface.clients)
							iface.clients = [];
						let client = {
							"mac": assoc.station,
							"ipv4_addresses": [ global.snoop[assoc.station] ],
							"ports": [ vap.ifname ]
						};
						push(iface.clients, client);
					}
				}

				let delta_iface = assoc.wds_interface || vap.ifname;
				assoc.delta_counters = telemetry_module.stations_deltas(assoc, delta_iface, global.previous);
			}

			ssid.iface = vap.ifname;
			if (global.ports && global.ports[vap.ifname]?.counters) {
				ssid.counters = global.ports[vap.ifname].counters || {};
				ssid.delta_counters = telemetry_module.ports_deltas(vap.ifname, global.ports, global.previous);
			}
			if (is_mesh(iface, wif)) {
				ssid.counters = global.ports['batman_mesh'].counters;
				ssid['mesh-path'] = mesh[vap.ifname];
			}
			if (global.dyn_vlans[vap.ifname]) {
				ssid.vlan_ifaces = [];
				for (let vlan in global.dyn_vlans[vap.ifname]) {
					let vid = +split(vlan, '-v')[1];
					push(ssid.vlan_ifaces, { ...(global.ports[vlan]?.counters || {}), ...{ vid} });
				}
			}
			push(ssids, ssid);
		}
		counter++;
	}
	
	return ssids;
};

export function collect_dynamic_vlans(state) {
	let dyn_vids = [];
	
	// Collect dynamic VLAN IDs from SSIDs
	if (index(global.stats.types, 'ssids') >= 0 && length(wifistatus)) {
		for (let radio, data in wifistatus) {
			for (let k, vap in data.interfaces) {
				if (!length(vap.config) ||
				    !length(vap.config.network) ||
				    !wifiiface[vap.ifname])
					continue;
				
				if (global.dyn_vlans[vap.ifname]) {
					for (let vlan in global.dyn_vlans[vap.ifname]) {
						let vid = +split(vlan, '-v')[1];
						push(dyn_vids, vid);
					}
				}
			}
		}
	}
	
	dyn_vids = uniq(dyn_vids);
	if (!length(dyn_vids))
		return;
		
	state.dynamic_vlans = [];
	for (let id in dyn_vids) {
		let dyn = {
			vid: id,
			tx_bytes: 0,
			tx_packets: 0,
			rx_bytes: 0,
			rx_packets: 0
		};
		for (let k, dev in global.devstats) {
			for (let k, vid in dev) {
				if (vid.vid != id)
					continue;
				dyn.tx_bytes += vid.tx.bytes;
				dyn.tx_packets += vid.tx.packets;
				dyn.rx_bytes += vid.rx.bytes;
				dyn.rx_packets += vid.rx.packets;
			}
		}
		push(state.dynamic_vlans, dyn);
	}
};

