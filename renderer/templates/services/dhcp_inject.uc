{% if (!services.is_present("dhcpinject")) return %}
{% let ssids = services.lookup_ssids("dhcp-inject") %}
{% let enable = length(ssids) %}
{% let iface_count = 0 %}
{% services.set_enabled("dhcpinject", enable) %}
{% 

let ports;
if (dhcp_inject && dhcp_inject.select_ports) {
    ports = ethernet.lookup_by_select_ports(dhcp_inject.select_ports)
}
else {
    ports = ["eth0"];
}

%}
{% if (!enable) return %}

# Dhcp Inject service configuration

set dhcpinject.uplink=device
{% for (let port in ports): %}
add_list dhcpinject.uplink.port={{ port }}
{% endfor %}

set dhcpinject.ssids=ssids
{% for (let ssid in ssids): %}
{%   iface_count += length(ssid.wifi_bands) %}
add_list dhcpinject.ssids.ssid={{ s(ssid.name) }}
{% endfor %}

set dhcpinject.dhcpinject=dhcpinject
set dhcpinject.dhcpinject.iface_count={{ iface_count }}
