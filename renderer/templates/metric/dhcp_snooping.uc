{% let interfaces = services.lookup_interfaces("dhcp-snooping") %}
{% let enable = length(interfaces) %}
{% if (!enable) return %}

# DHCP Snooping configuration

set event.dhcp=event
set event.dhcp.type=dhcp
set event.dhcp.filter='*'
{% for (let n, filter in dhcp_snooping.filters): %}
{{ n ? 'add_list' : 'set' }} event.dhcp.filter={{ filter }}
{% endfor %}

{% for (let interface in interfaces): %}
{%    if (interface.role != "downstream") continue %}
{%	let name = ethernet.calculate_name(interface) %}
add dhcpsnoop device
set dhcpsnoop.@device[-1].name={{ s(name) }}
set dhcpsnoop.@device[-1].ingress=1
set dhcpsnoop.@device[-1].egress=1
{% endfor %}
