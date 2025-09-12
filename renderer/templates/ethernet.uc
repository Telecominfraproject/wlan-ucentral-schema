{% let eth_ports = ethernet.lookup_by_select_ports(ports.select_ports) %}
{% for (let port in eth_ports): %}
{% let nport = replace(port, '.', '_'); %}
set network.{{ nport }}=device
set network.{{ nport }}.name={{ s(port) }}
set network.{{ nport }}.ifname={{ s(port) }}
set network.{{ nport }}.enabled={{ b(ports.enabled) }}
{% if (!ports.speed && !ports.duplex) continue %}
set network.{{ nport }}.speed={{ ports.speed }}
set network.{{ nport }}.duplex={{ b(ports.duplex == "full") }}

{% endfor %}
{%
// PoE configuration
if (ports?.poe && services.is_present("poe")) {
	let ports_name = ethernet.lookup_name_by_select_ports(ports.select_ports);
	let ports_num = [];
	for (let port_name in ports_name) {
		let ret = wildcard(port_name, "LAN*");
		if (ret) {
			let port_num = substr(port_name, 3);
			push(ports_num, port_num);
		}
		//TODO: WAN PoE handle.
	}
	
	if (length(ports_num) > 0) {
%}
#poe
{% 		for (let num in ports_num): %}
set poe.@port[{{ num-1 }}].admin_mode={{ b(ports.poe.admin_mode) }}
{% 		endfor %}
{%
	}
}
%}