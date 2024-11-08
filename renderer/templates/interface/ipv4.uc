{% if (interface.role == 'upstream' && ethernet.has_vlan(interface)): %}
set network.{{ name }}.ip4table={{ routing_table.get(this_vid) }}
{% endif %}
{% if (ipv4_mode == 'static'): %}
set network.{{ name }}.ipaddr={{ ipv4.subnet }}
set network.{{ name }}.gateway={{ ipv4.gateway }}
{% else %}
set network.{{ name }}.peerdns={{ b(!length(ipv4.use_dns)) }}
{% endif %}
{% if (ipv4_mode == 'dynamic'): %}
set network.{{ name }}.vendorid={{ ipv4.vendor_class }}
set network.{{ name }}.reqopts='{{ join(' ', ipv4.request_options) }}'
{% endif %}
{%  for (let dns in ipv4.use_dns): %}
add_list network.{{ name }}.dns={{ dns }}
{%  endfor %}
