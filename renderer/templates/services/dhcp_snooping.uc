{% services.set_enabled("dhcpsnoop", true) %}

# DHCP Snooping configuration

{% for (let interface in state.interfaces): %}
{%   if (interface.role != 'upstream') continue %}
{%      for (let name in ethernet.lookup_by_interface_vlan(interface)): %}
add dhcpsnoop device
set dhcpsnoop.@device[-1].name={{ s(name) }}
set dhcpsnoop.@device[-1].ingress=1
set dhcpsnoop.@device[-1].egress=1
{%     endfor %}
{% endfor %}
