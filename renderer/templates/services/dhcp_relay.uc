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
{% for (let vlan in dhcp_relay.vlans||[]): %}
add_list dhcprelay.relay.vlans={{ vlan.vlan }}
{% endfor %}
{% for (let port in ports): %}
add_list dhcprelay.relay.upstream={{ port }}
{% endfor %}
{% for (let vlan in dhcp_relay.vlans||[]): %}
set dhcprelay.vlan{{vlan.vlan}}=config
set dhcprelay.vlan{{vlan.vlan}}.server={{ s(vlan.relay_server) }}
set dhcprelay.vlan{{vlan.vlan}}.circuit_id={{ s(vlan?.circuit_id_format) }}
set dhcprelay.vlan{{vlan.vlan}}.remote_id={{ s(vlan?.remote_id_format) }}
{% endfor %}
