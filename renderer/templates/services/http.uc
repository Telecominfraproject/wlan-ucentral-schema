{% if (!services.is_present("uhttpd")) return %}
{% let interfaces = services.lookup_interfaces("http") %}
{% let enable = length(interfaces) %}
{% services.set_enabled("uhttpd", enable) %}
{% services.set_enabled("rpcd", enable) %}
{% if (!enable) return %}

# HTTP service configuration

add uhttpd uhttpd
set uhttpd.@uhttpd[-1].redirect_https='0'
set uhttpd.@uhttpd[-1].home='/www'
set uhttpd.@uhttpd[-1].rfc1918_filter='1'
set uhttpd.@uhttpd[-1].max_requests='3'
set uhttpd.@uhttpd[-1].max_connections='100'
set uhttpd.@uhttpd[-1].cert='/etc/uhttpd.crt'
set uhttpd.@uhttpd[-1].key='/etc/uhttpd.key'
set uhttpd.@uhttpd[-1].cgi_prefix='/cgi-bin'
set uhttpd.@uhttpd[-1].lua_prefix='/cgi-bin/luci=/usr/lib/lua/luci/sgi/uhttpd.lua'
set uhttpd.@uhttpd[-1].script_timeout='60'
set uhttpd.@uhttpd[-1].network_timeout='30'
set uhttpd.@uhttpd[-1].http_keepalive='20'
set uhttpd.@uhttpd[-1].tcp_keepalive='1'
set uhttpd.@uhttpd[-1].ubus_prefix='/ubus'
add_list uhttpd.@uhttpd[-1].listen_http='0.0.0.0:{{ http.http_port || 80 }}'
{% let interfaces = services.lookup_interfaces("http") %}
{% for (let interface in interfaces): %}
{%    let name = ethernet.calculate_name(interface) %}

add firewall rule
set firewall.@rule[-1].name='Allow-http-{{ name }}'
set firewall.@rule[-1].src='{{ name }}'
set firewall.@rule[-1].port='{{ http.http_port || 80 }}'
set firewall.@rule[-1].proto='tcp'
set firewall.@rule[-1].target='ACCEPT'
{% endfor %}
