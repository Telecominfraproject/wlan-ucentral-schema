{% for (let port in dot1x_ports): %}
add ieee8021x port
set ieee8021x.@port[-1].iface={{ s(port) }}
set ieee8021x.@port[-1].vlan={{ this_vid }}
set ieee8021x.@port[-1].upstream={{ b(interface.role == 'upstream') }}
{%   for (let port in keys(eth_ports)): %}
add_list ieee8021x.@port[-1].wan_ports={{ s(port) }}
{%   endfor %}

{%
	let nport = replace(port, '.', '_')
%}
set network.{{ s(nport) }}=device
set network.{{ s(nport) }}.name={{ s(port) }}
set network.{{ s(nport) }}.auth='1'
set network.{{ s(nport) }}.auth_vlan={{ interface.dot1x_vlan }}:u

{%   if (interface.role == 'upstream'): %}
add_list network.up.ports={{ s(port) }}
{%   else %}
add_list network.down.ports={{ s(port) }}
{%   endif %}
{% endfor %}
