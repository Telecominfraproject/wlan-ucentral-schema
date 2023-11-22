{% let eth_ports = ethernet.lookup_by_select_ports(ports.select_ports) %}
{% for (let port in eth_ports):
	port = replace(port, '.', '_');
%}
set network.{{ port }}=device
set network.{{ port }}.name={{ s(port) }}
set network.{{ port }}.ifname={{ s(port) }}
set network.{{ port }}.enabled={{ b(ports.enabled) }}
{% if (!ports.speed && !ports.duplex) continue %}
set network.{{ port }}.speed={{ ports.speed }}
set network.{{ port }}.duplex={{ ports.duplex == "full" ? true : false }}

{% endfor %}
