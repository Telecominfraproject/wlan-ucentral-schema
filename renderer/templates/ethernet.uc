{% let eth_ports = ethernet.lookup_by_select_ports(ports.select_ports) %}
{% for (let port in eth_ports): %}
add network device
set network.@device[-1].name={{ s(port) }}
set network.@device[-1].ifname={{ s(port) }}
set network.@device[-1].enabled={{ ports.enabled }}
{% if (!ports.speed && !ports.duplex) continue %}
set network.@device[-1].speed={{ ports.speed }}
set network.@device[-1].duplex={{ ports.duplex == "full" ? true : false }}

{% endfor %}
