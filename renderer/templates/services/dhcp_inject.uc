{% let ifaces = services.lookup_interfaces_by_ssids("dhcp-inject") %}
{% if (!length(ifaces)) { return } %}
{% let upstreams = [] %}
{% for (let iface in ifaces): %}
{%    if (iface.role == "upstream") { push(upstreams, iface) } %}
{% endfor %}

{% let enabled = length(upstreams) %}
{% services.set_enabled("dhcpinject", enabled) %}

{% for (let upstream in upstreams): %}

{%    let iface_name = ethernet.calculate_name(upstream) %}
{%    let count = 0, freqs = [] %}

set dhcpinject.{{ upstream.name }}=network
set dhcpinject.{{ upstream.name }}.upstream={{ s(iface_name) }}

{%    for (let ssid in upstream.ssids): %}
{%       count += length(ssid.wifi_bands) %}
{%       for (let freq in ssid.wifi_bands): %}
{%          push(freqs, freq) %}
add_list dhcpinject.{{ upstream.name }}.ssid{{ freq }}={{ s(ssid.name) }}
{%       endfor %}
{%    endfor %}

{%    for (let freq in uniq(freqs)): %}
add_list dhcpinject.{{ upstream.name }}.freq={{ s(freq) }}
{%    endfor%}
set dhcpinject.{{ upstream.name }}.count={{ count }}

{% endfor %}
