{%
	if (!length(ntp))
		return;
	let interfaces = services.lookup_interfaces("ntp");
%}
set system.ntp.enable_server={{ b(length(interfaces)) }}
{%	if (ntp.servers): %}
set system.ntp.use_dhcp=0
delete system.ntp.server
{%	endif %}
{%	for (let server in ntp.servers): %}
add_list system.ntp.server={{ s(server) }}
{%	endfor

	/* open the port on all interfaces that select ssh */
	for (let interface in interfaces):
		let name = ethernet.calculate_name(interface);
%}
add firewall rule
set firewall.@rule[-1].name='Allow-ntp-{{ name }}'
set firewall.@rule[-1].src='{{ name }}'
set firewall.@rule[-1].dest_port='123'
set firewall.@rule[-1].proto='udp'
set firewall.@rule[-1].target='ACCEPT'
{%	endfor %}
