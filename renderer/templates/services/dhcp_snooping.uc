{% services.set_enabled("dhcpsnoop", true) %}

# DHCP Snooping configuration

{% for (let interface in state.interfaces): %}
{%   if (interface.role != 'upstream') continue %}
{%      for (let name in ethernet.lookup_by_interface_vlan(interface)): %}
set dhcpsnoop.{{ name }}=device
set dhcpsnoop.{{ name }}.name={{ s(name) }}
set dhcpsnoop.{{ name }}.ingress=1
set dhcpsnoop.{{ name }}.egress=1
{%     endfor %}
{% endfor %}
