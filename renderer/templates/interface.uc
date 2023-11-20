{%
	let has_downstream_relays = false;
	let dest;

	// Skip interfaces previously marked as conflicting.
	if (interface.conflicting) {
		warn("Skipping conflicting interface declaration");

		return;
	}

	// Skip upstream interfaces that try to use a wireguard overlay
	if (interface.role == 'upstream' && 'wireguard-overlay' in interface.services) {
		warn("Skipping interface. wireguard-overlay is not allowed on upstream interfaces.");

		return;
	}

	// Check this interface for role/vlan uniqueness...
	let this_vid = interface.vlan.id || interface.vlan.dyn_id;

	for (let other_interface in state.interfaces) {
		if (other_interface == interface)
			continue;

		if (!other_interface.ethernet && length(interface.ssids) == 1)
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

	// check if a downstream interface with a vlan has a matching upstream interface
	if (ethernet.has_vlan(interface) && interface.role == "downstream" && index(vlans, this_vid) < 0) {
		warn("Trying to create a downstream interface with a VLAN ID, without matching upstream interface.");
		return;
	}

	// reject static config that has no subnet
	if (interface.role == 'upstream' && interface.ipv4?.addressing == 'static')
		if (!interface.ipv4?.subnet || !interface.ipv4?.use_dns || !interface.ipv4?.gateway)
			die('invalid static interface settings');

	// resolve auto prefixes
	if (wildcard(interface.ipv4?.subnet, 'auto/*')) {
		try {
			interface.ipv4.subnet = ipcalc.generate_prefix(state, interface.ipv4.subnet, false);
		}
		catch (e) {
			warn("Unable to allocate a suitable IPv4 prefix: %s, ignoring interface", e);
			return;
		}
	}

	if (wildcard(interface.ipv6?.subnet, 'auto/*')) {
		try {
			interface.ipv6.subnet = ipcalc.generate_prefix(state, interface.ipv6.subnet, true);
		}
		catch (e) {
			warn("Unable to allocate a suitable IPv6 prefix: %s, ignoring interface", e);
			return;
		}
	}

	// Captive Portal is only supported on downstream interfaces
	if (interface.captive && interface.role != 'downstream') {
		warn("Trying to create a Captive Portal on a none downstream interface.");
		return;
	}

	// Port forwardings are only supported on downstream interfaces
	if ((interface.ipv4?.port_forward || interface.ipv6?.port_forward) && interface.role != 'downstream') {
		warn("Port forwardings are only supported on downstream interfaces.");
		return;
	}

	// Traffic accept rules are only supported on downstream interfaces
	if (interface.ipv6?.traffic_allow && interface.role != 'downstream') {
		warn("Traffic accept rules are only supported on downstream interfaces.");
		return;
	}

	// Gather related BSS modes and ethernet ports.
	let bss_modes = map(interface.ssids, ssid => ssid.bss_mode);
	let eth_ports = ethernet.lookup_by_interface_vlan(interface);
	let dot1x_ports = ethernet.lookup_by_select_ports(interface.ieee8021x_ports);
	let swconfig;
	if (interface.role == 'upstream')
		swconfig = ethernet.switch_by_interface_vlan(interface);

	// If at least one station mode SSID is part of this interface then we must
	// not bridge at all. Having any other SSID or any number of matching ethernet
	// ports in such a case is a semantic error.
	if ('sta' in bss_modes && (length(eth_ports) > 0 || length(bss_modes) > 1)) {
		warn("Station mode SSIDs cannot be bridged with ethernet ports or other SSIDs, ignoring interface");

		return;
	}

	// Compute unique logical name and netdev name to use
	let name = ethernet.calculate_name(interface);
	let bridgedev = 'up';
	if (capab.platform != "switch" && interface.role == "downstream")
		bridgedev = 'down';
	let netdev = name;
	let network = name;

	// Determine the IPv4 and IPv6 configuration modes and figure out if we
	// can set them both in a single interface (automatic) or whether we need
	// two logical interfaces due to different protocols.
	let ipv4_mode = interface.ipv4 ? interface.ipv4.addressing : 'none';
	let ipv6_mode = interface.ipv6 ? interface.ipv6.addressing : 'none';

	// If no metric is defined explicitly, any upstream interfaces will default
	// to 5 and downstream interfaces will default to 10
	if (!interface.metric && interface.role == "upstream")
		interface.metric = 5;
	if (!interface.metric && interface.role == "downstream")
		interface.metric = 10;

	if (interface.isolate_hosts) {
		interface.bridge ??= {};
		interface.bridge.isolate_ports = true;
	}

	// If this interface is a tunnel, we need to create the interface
	// in a different way
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
			include('interface/ssid.uc', {
				location: location + '/ssids/' + i,
				ssid: { ...ssid, bss_mode: mode },
				count,
				name,
				network,
			});
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

			}
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
