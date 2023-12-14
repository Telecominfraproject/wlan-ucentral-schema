add network bridge-vlan
set network.@bridge-vlan[-1].device={{ bridgedev }}
set network.@bridge-vlan[-1].vlan={{ this_vid }}
{%  for (let port in keys(eth_ports)): %}
add_list network.@bridge-vlan[-1].ports={{ port }}{{ ethernet.port_vlan(interface, eth_ports[port]) }}
{%  endfor %}
{% if (interface.tunnel?.proto == "mesh"): %}
add_list network.@bridge-vlan[-1].ports=batman{{ ethernet.has_vlan(interface) ? "." + this_vid + ":t" : '' }}
{% endif %}
{% if (interface.tunnel?.proto == "vxlan"): %}
add_list network.@bridge-vlan[-1].ports={{ name }}_vx
{% endif %}
{% if (interface.tunnel?.proto == "gre"): %}
add_list network.@bridge-vlan[-1].ports=gre4t-gre.{{ interface.vlan.id }}
{% endif %}
{% if (interface.tunnel?.proto == "gre6"): %}
add_list network.@bridge-vlan[-1].ports=gre6t-greip6.{{ interface.vlan.id }}
{% endif %}
{% if ('vxlan-overlay' in interface.services): %}
add_list network.@bridge-vlan[-1].ports=vx-unet
{% endif %}
{% if (interface.bridge): %}
set network.@bridge-vlan[-1].txqueuelen={{ interface.bridge.tx_queue_len }}
set network.@bridge-vlan[-1].isolate={{ b(interface.bridge.isolate_ports || interface.isolate_hosts) }}
set network.@bridge-vlan[-1].mtu={{ interface.bridge.mtu }}
{% endif %}

add network device
set network.@device[-1].type=8021q
set network.@device[-1].name={{ name }}
set network.@device[-1].ifname={{ bridgedev }}
set network.@device[-1].vid={{ this_vid }}

{% if (interface.vlan_awareness?.first): %}
{%   let vlan = interface.vlan_awareness.first;
     if (interface.vlan_awareness.last)
	     vlan += '-' + interface.vlan_awareness.last; %}
{%   for (let port in keys(eth_ports)): %}
add network device
set network.@device[-1].name={{ port }}
set network.@device[-1].vlan={{ vlan }}
{%   endfor %}
{%   if (interface.role == 'upstream'): %}
set network.up.vlan={{ vlan }}
{%   endif %}
{%   if (interface.role == 'downstream'): %}
set network.down.vlan={{ vlan }}
{%   endif %}
{% endif %}

{% if (interface.role == 'upstream'): %}
{%  for (let port in keys(eth_ports)):
	let section = replace(port, '.', '_');
%}
set udevstats.{{ section }}=device
set udevstats.{{ section }}.name={{ s(port) }}
add_list udevstats.{{ section }}.vlan={{ s(interface.vlan.id || 0) }}
{%  endfor %}
{% endif %}

{% if (interface.vlan.id && swconfig): %}
add network switch_vlan
set network.@switch_vlan[-1].device={{ s(swconfig.name) }}
set network.@switch_vlan[-1].vlan={{ s(this_vid) }}
set network.@switch_vlan[-1].ports={{s(swconfig.ports)}}
{% endif %}

{% if (interface.role == 'upstream' && swconfig && !interface.vlan.id): %}
{%   for (let dev in keys(eth_ports)):
        if (ethernet.swconfig && ethernet.swconfig[dev]): %}
set event.config.swconfig={{ethernet.swconfig[dev].switch?.name}}
add_list event.config.swconfig_ports={{ethernet.swconfig[dev].swconfig}}t
add_list event.config.swconfig_ports={{ethernet.swconfig[dev].switch?.port}}t
{%     endif %}
{%   endfor %}
{% endif %}
