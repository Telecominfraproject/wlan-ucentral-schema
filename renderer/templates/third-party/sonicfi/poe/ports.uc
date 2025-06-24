{% if (ports?.select_ports): %}
{% let ports_name = ethernet_poe.lookup_by_select_ports(ports.select_ports) %}
{%
	let ports_num = [];
	for (let port_name in ports_name){
		let ret = wildcard(port_name, "LAN?*");
		if (ret){
			let port_num = substr(port_name, 3);
			push(ports_num, port_num);
		}
		//TODO: WAN PoE handle.
	}
%}
{% for (let num in ports_num): %}
set sonicfi_poe.@port[{{ num-1 }}].admin_mode={{ b(ports.admin_mode) }}
{% endfor %}
{% endif %}
