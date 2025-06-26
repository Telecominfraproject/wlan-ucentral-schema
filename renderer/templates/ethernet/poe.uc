#poe
{% if (!services.is_present("poe")) return %}
{%
let ports_name = ethernet.lookup_name_by_select_ports(select_ports);
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
set poe.@port[{{ num-1 }}].admin_mode={{ b(poe.admin_mode) }}
{% endfor %}
