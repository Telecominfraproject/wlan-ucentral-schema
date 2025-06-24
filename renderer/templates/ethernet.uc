{% let eth_ports = ethernet.lookup_by_select_ports(ports.select_ports) %}
{% for (let port in eth_ports): %}
{% let nport = replace(port, '.', '_'); %}
set network.{{ nport }}=device
set network.{{ nport }}.name={{ s(port) }}
set network.{{ nport }}.ifname={{ s(port) }}
set network.{{ nport }}.enabled={{ ports.enabled }}
{% if (!ports.speed && !ports.duplex) continue %}
set network.{{ nport }}.speed={{ ports.speed }}
set network.{{ nport }}.duplex={{ ports.duplex == "full" ? true : false }}

{% endfor %}
{%
if (ports?.poe) {
	include("ethernet/poe.uc",{
		select_ports: ports.select_ports,
		poe: ports.poe
	});
}
%}
