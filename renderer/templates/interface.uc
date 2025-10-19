{%
	// Constants
	const DEFAULT_METRICS = {
		upstream: 5,
		downstream: 10
	};

	const BRIDGE_DEVICES = {
		upstream: 'up',
		downstream: 'down'
	};

	const TUNNEL_PROTOCOLS = ['mesh', 'l2tp', 'vxlan', 'gre', 'gre6'];
	const WDS_MODES = ['wds-sta', 'wds-ap'];

	// Helper functions

	// has_ functions - check for existence/availability
	function has_conflicting_interface() {
		return !!interface.conflicting;
	}

	function has_wireguard_overlay() {
		return 'wireguard-overlay' in interface.services;
	}

	function has_vxlan_overlay() {
		return 'vxlan-overlay' in interface.services;
	}

	function has_vlan() {
		return ethernet.has_vlan(interface);
	}

	function has_ethernet_ports() {
		return length(eth_ports) > 0;
	}

	function has_multiple_ssids() {
		return length(interface.ssids) > 1;
	}

	function has_single_ssid() {
		return length(interface.ssids) == 1;
	}

	function has_captive_portal() {
		return !!interface.captive;
	}

	function has_port_forwards() {
		return interface.ipv4?.port_forward || interface.ipv6?.port_forward;
	}

	function has_traffic_allow() {
		return !!interface.ipv6?.traffic_allow;
	}

	function has_dot1x_ports() {
		return length(dot1x_ports) > 0;
	}

	function has_ipv4_config() {
		return !!interface.ipv4;
	}

	function has_ipv6_config() {
		return !!interface.ipv6;
	}

	// is_ functions - boolean checks/validation
	function is_upstream_interface() {
		return interface.role == 'upstream';
	}

	function is_downstream_interface() {
		return interface.role == 'downstream';
	}

	function is_static_ipv4() {
		return interface.ipv4?.addressing == 'static';
	}

	function is_tunnel_protocol(proto) {
		return tunnel_proto == proto;
	}

	function is_station_mode_incompatible() {
		return 'sta' in bss_modes && (has_ethernet_ports() || has_multiple_ssids());
	}

	function is_switch_platform() {
		return capab.platform == "switch";
	}

	function is_valid_downstream_vlan(vid) {
		return !(has_vlan() && is_downstream_interface() && index(vlans, vid) < 0);
	}

	function is_valid_static_config() {
		if (!is_upstream_interface() || !is_static_ipv4())
			return true;
		return interface.ipv4?.subnet && interface.ipv4?.use_dns && interface.ipv4?.gateway;
	}

	// validate_ functions - complex validation logic
	function validate_interface_conflicts() {
		if (has_conflicting_interface()) {
			warn("Skipping conflicting interface declaration");
			return false;
		}

		if (is_upstream_interface() && has_wireguard_overlay()) {
			warn("Skipping interface. wireguard-overlay is not allowed on upstream interfaces.");
			return false;
		}

		return true;
	}

	function validate_vlan_uniqueness() {
		for (let other_interface in state.interfaces) {
			if (other_interface == interface)
				continue;

			if (!other_interface.ethernet && has_single_ssid())
				continue;

			let other_vid = other_interface.vlan.id || '';

			if (interface.role === other_interface.role && this_vid === other_vid) {
				warn("Multiple interfaces with same role and VLAN ID defined, ignoring conflicting interface");
				other_interface.conflicting = true;
			}

			if (other_interface.role == 'downstream' &&
			    other_interface.ipv6 &&
			    other_interface.ipv6.dhcpv6 &&
			    other_interface.ipv6.dhcpv6.mode == 'relay')
				has_downstream_relays = true;
		}

		return true;
	}

	function validate_downstream_vlan(vid) {
		if (!is_valid_downstream_vlan(vid)) {
			warn("Trying to create a downstream interface with a VLAN ID, without matching upstream interface.");
			return false;
		}
		return true;
	}

	function validate_static_config() {
		if (!is_valid_static_config()) {
			die('invalid static interface settings');
			return false;
		}
		return true;
	}

	function validate_feature_restrictions() {
		if (has_captive_portal() && !is_downstream_interface()) {
			warn("Trying to create a Captive Portal on a none downstream interface.");
			return false;
		}

		if (has_port_forwards() && !is_downstream_interface()) {
			warn("Port forwardings are only supported on downstream interfaces.");
			return false;
		}

		if (has_traffic_allow() && !is_downstream_interface()) {
			warn("Traffic accept rules are only supported on downstream interfaces.");
			return false;
		}

		return true;
	}

	function validate_station_mode_compatibility() {
		if (is_station_mode_incompatible()) {
			warn("Station mode SSIDs cannot be bridged with ethernet ports or other SSIDs, ignoring interface");
			return false;
		}
		return true;
	}

	// normalize_ functions - data transformation
	function normalize_interface_metric() {
		if (!interface.metric) {
			if (is_upstream_interface())
				interface.metric = DEFAULT_METRICS.upstream;
			else if (is_downstream_interface())
				interface.metric = DEFAULT_METRICS.downstream;
		}
	}

	function normalize_bridge_device() {
		if (is_switch_platform())
			return BRIDGE_DEVICES.upstream;
		return is_downstream_interface() ? BRIDGE_DEVICES.downstream : BRIDGE_DEVICES.upstream;
	}

	function normalize_isolate_hosts() {
		if (interface.isolate_hosts) {
			interface.bridge ??= {};
			interface.bridge.isolate_ports = true;
		}
	}

	function normalize_auto_prefixes() {
		if (wildcard(interface.ipv4?.subnet, 'auto/*')) {
			try {
				interface.ipv4.subnet = ipcalc.generate_prefix(state, interface.ipv4.subnet, false);
			} catch (e) {
				warn("Unable to allocate a suitable IPv4 prefix: %s, ignoring interface", e);
				return false;
			}
		}

		if (wildcard(interface.ipv6?.subnet, 'auto/*')) {
			try {
				interface.ipv6.subnet = ipcalc.generate_prefix(state, interface.ipv6.subnet, true);
			} catch (e) {
				warn("Unable to allocate a suitable IPv6 prefix: %s, ignoring interface", e);
				return false;
			}
		}

		return true;
	}

	// Variables initialization (declare early for function access)
	let has_downstream_relays = false;
	let dest;
	let this_vid;
	let bss_modes;
	let eth_ports;
	let dot1x_ports;
	let swconfig;

	// Main validation and setup
	if (!validate_interface_conflicts())
		return;

	// Variable assignments
	this_vid = interface.vlan.id || interface.vlan.dyn_id;
	bss_modes = map(interface.ssids, ssid => ssid.bss_mode);
	eth_ports = ethernet.lookup_by_interface_vlan(interface);
	dot1x_ports = ethernet.lookup_by_select_ports(interface.ieee8021x_ports);
	swconfig = is_upstream_interface() ? ethernet.switch_by_interface_vlan(interface) : null;

	// Validate VLAN uniqueness and detect relay configurations
	if (!validate_vlan_uniqueness())
		return;

	if (!validate_downstream_vlan(this_vid))
		return;

	if (!validate_static_config())
		return;

	// Resolve auto prefixes
	if (!normalize_auto_prefixes())
		return;

	// Validate feature restrictions
	if (!validate_feature_restrictions())
		return;

	// Station mode compatibility check
	if (!validate_station_mode_compatibility())
		return;

	// Compute interface names and configuration
	let name = ethernet.calculate_name(interface);
	let bridgedev = normalize_bridge_device();
	let netdev = name;
	let network = name;

	// Determine IP configuration modes
	let ipv4_mode = interface.ipv4 ? interface.ipv4.addressing : 'none';
	let ipv6_mode = interface.ipv6 ? interface.ipv6.addressing : 'none';

	// Normalize interface configuration
	normalize_interface_metric();
	normalize_isolate_hosts();

	// Determine tunnel protocol
	let tunnel_proto = interface.tunnel ? interface.tunnel.proto : '';

	//
	// Create the actual UCI sections
	//

	if (interface.broad_band) {
		include("interface/broadband.uc", { interface, name, location, eth_ports, raw_ports });
		return;
	}

	// tunnel interfaces need additional sections
	if (tunnel_proto in [ "mesh", "l2tp", "vxlan", "gre", "gre6" ])
		include("interface/" + tunnel_proto + ".uc", { interface, name, eth_ports, location, netdev, ipv4_mode, ipv6_mode, this_vid });

	if (!interface.ethernet && length(interface.ssids) == 1 && !tunnel_proto && !("vxlan-overlay" in interface.services)) {
		if (interface.role == 'downstream')
			interface.type = 'bridge';
		netdev = '';
	} else if (tunnel_proto == 'vxlan') {
		netdev = '@' + name + '_vx';
		interface.type = 'bridge';
	} else if (tunnel_proto != 'gre' && tunnel_proto != 'gre6')
		// anything else requires a bridge-vlan
		include("interface/bridge-vlan.uc", { interface, name, eth_ports, this_vid, bridgedev, swconfig });

	if (interface.role == "downstream" && "wireguard-overlay" in interface.services)
		dest = 'unet';

	include("interface/common.uc", {
		name, this_vid, netdev,
		ipv4_mode, ipv4: interface.ipv4 || {},
		ipv6_mode, ipv6: interface.ipv6 || {}
	});

	include('interface/firewall.uc', { name, ipv4_mode, ipv6_mode, dest });

	if (interface.ipv4 || interface.ipv6) {
		include('interface/dhcp.uc', {
			ipv4: interface.ipv4 || {},
			ipv6: interface.ipv6 || {},
			has_downstream_relays
		});
	}

	let count = 0;
	for (let i, ssid in interface.ssids) {
		let modes = (ssid.bss_mode == "wds-repeater") ?
			[ "wds-sta", "wds-ap" ] : [ ssid.bss_mode ];
		for (let mode in modes) {
			if (ssid?.encryption?.proto == 'owe-transition') {
				ssid.encryption.proto = 'none';
				include('interface/ssid.uc', {
					location: location + '/ssids/' + i + '_owe',
					ssid: { ...ssid, bss_mode: mode },
					count,
					name,
					network,
					owe: true,
				});
				ssid.encryption.proto = 'owe-transition';
			}

			include('interface/ssid.uc', {
				location: location + '/ssids/' + i,
				ssid: { ...ssid, bss_mode: mode },
				count,
				name,
				tunnel_proto,
				network,
			});
			count++;
		}
	}

	if (interface.captive)
		include('interface/captive.uc', { name });

	if (length(dot1x_ports))
		include('interface/ieee8021x.uc', { dot1x_ports, interface, eth_ports, this_vid });

%}
{% if (tunnel_proto == 'mesh'): %}
set network.{{ name }}.batman=1
{% endif %}

{% if (interface.role == "downstream" && "wireguard-overlay" in interface.services): %}
add network rule
set network.@rule[-1].in='{{name}}'
set network.@rule[-1].lookup='{{ routing_table.get('wireguard_overlay') }}'
{% endif %}
