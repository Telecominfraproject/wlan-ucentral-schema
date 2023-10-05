{% for (let port in dot1x_ports): %}
add ieee8021x port
set ieee8021x.@port[-1].iface={{ s(port) }}
set ieee8021x.@port[-1].vlan={{ this_vid }}
set ieee8021x.@port[-1].upstream={{ b(interface.role == 'upstream') }}
{%   for (let port in keys(eth_ports)): %}
add_list ieee8021x.@port[-1].wan_ports={{ s(port) }}
{%   endfor %}

set network.{{ replace(port, '.', '_') }}=device
set network.@device[-1].name={{ s(port) }}
set network.@device[-1].auth='1'
set network.@device[-1].auth_vlan={{ interface.dot1x_vlan }}:u

{%   if (interface.role == 'upstream'): %}
add_list network.up.ports={{ s(port) }}
{%   else %}
add_list network.down.ports={{ s(port) }}
{%   endif %}
{% endfor %}
