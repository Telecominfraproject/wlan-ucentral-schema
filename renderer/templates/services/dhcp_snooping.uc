{% services.set_enabled("dhcpsnoop", true) %}

# DHCP Snooping configuration

{%
	let names = [];
	for (let interface in state.interfaces) {
		if (interface.role == 'upstream') {
			 for (let name in ethernet.lookup_by_interface_vlan(interface))
				 push(names, name);
		} else
			push(names, ethernet.calculate_name(interface));
	}
	for (let name in uniq(names)):
%}
add dhcpsnoop device
set dhcpsnoop.@device[-1].name={{ s(name) }}
set dhcpsnoop.@device[-1].ingress=1
set dhcpsnoop.@device[-1].egress=1
{%	endfor %}
