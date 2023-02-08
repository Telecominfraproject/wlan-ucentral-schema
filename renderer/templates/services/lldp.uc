{% if (!services.is_present("lldpd")) return %}
{% let interfaces = services.lookup_interfaces("lldp") %}
{% let enable = length(interfaces) %}
{% services.set_enabled("lldpd", enable) %}
{% if (!enable) return %}

# LLDP service configuration

set lldpd.config.enable=1
set lldpd.config.lldp_description={{ s(lldp.describe) }}
set lldpd.config.lldp_location={{ s(lldp.location) }}
{% for (let interface in interfaces): %}
{%  for (let port in ethernet.lookup_by_interface_spec(interface)): %}
add_list lldpd.config.interface={{ s(port) }}
{%  endfor %}
{% endfor %}
