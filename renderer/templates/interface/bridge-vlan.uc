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
set network.@bridge-vlan[-1].isolate={{interface.bridge.isolate_ports }}
set network.@bridge-vlan[-1].mtu={{ interface.bridge.mtu }}
{% endif %}

add network device
set network.@device[-1].type=8021q
set network.@device[-1].name={{ name }}
set network.@device[-1].ifname={{ bridgedev }}
set network.@device[-1].vid={{ this_vid }}

{% if (interface.role == 'upstream'): %}
{%  for (let port in keys(eth_ports)): %}
add udevstats device
set udevstats.@device[-1].name={{ s(port) }}
add_list udevstats.@device[-1].vlan={{ s(interface.vlan.id || 0) }}
{%  endfor %}
{% endif %}
