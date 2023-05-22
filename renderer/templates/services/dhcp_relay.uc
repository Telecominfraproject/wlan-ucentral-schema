{%
if (!services.is_present("dhcprelay") || !dhcp_relay)
	return;
let interfaces = services.lookup_interfaces("dhcp-relay");
let ports = ethernet.lookup_by_select_ports(dhcp_relay.select_ports);
let enable = length(interfaces) && length(ports); 
services.set_enabled("dhcprelay", enable);
if (!enable)
	return;

%}

# DHCP-relay service configuration

set firewall.dhcp_relay=rule
set firewall.dhcp_relay.name='Allow-DHCP-Relay'
set firewall.dhcp_relay.src='{{ s(ethernet.find_interface("upstream", 0)) }}'
set firewall.dhcp_relay.dest_port='67'
set firewall.dhcp_relay.family='ipv4'
set firewall.dhcp_relay.proto='udp'
set firewall.dhcp_relay.target='ACCEPT'

set dhcprelay.relay=bridge
set dhcprelay.relay.name=up
{% for (let iface in interfaces):
	if (iface.vlan?.id) %}
add_list dhcprelay.relay.vlans={{ iface.vlan.id }}
{% endfor %}
{% for (let port in ports): %}
add_list dhcprelay.relay.upstream={{ port }}
{% endfor %}
set dhcprelay.config=config
set dhcprelay.config.server={{ s(dhcp_relay.relay_server) }}
