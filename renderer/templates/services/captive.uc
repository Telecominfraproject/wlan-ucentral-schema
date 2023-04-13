{%
if (!services.is_present("spotfilter"))
	return;
let interfaces = services.lookup_interfaces_by_ssids("captive");
let enable = length(interfaces);
if (enable && enable > 1) {
	warn('captive portal can only run on a single interface');
	enable = false;

}
services.set_enabled("spotfilter", enable);
services.set_enabled("uspot", enable);
if (!enable)
	return;
%}

{% for (let interface in uniq(interfaces)): %}
{%   let name = ethernet.calculate_name(interface) %}
add firewall redirect
set firewall.@redirect[-1].name='Redirect-captive-{{ name }}'
set firewall.@redirect[-1].src='{{ name }}'
set firewall.@redirect[-1].src_dport='80'
set firewall.@redirect[-1].proto='tcp'
set firewall.@redirect[-1].target='DNAT'
set firewall.@redirect[-1].mark='1/127'

add firewall rule
set firewall.@rule[-1].name='Allow-pre-captive-{{ name }}'
set firewall.@rule[-1].src='{{ name }}'
set firewall.@rule[-1].dest_port='80'
set firewall.@rule[-1].proto='tcp'
set firewall.@rule[-1].target='ACCEPT'
set firewall.@rule[-1].mark='1/127'

add firewall rule
set firewall.@rule[-1].name='Allow-captive-{{ name }}'
set firewall.@rule[-1].src='{{ name }}'
set firewall.@rule[-1].dest_port='80'
set firewall.@rule[-1].proto='tcp'
set firewall.@rule[-1].target='ACCEPT'
set firewall.@rule[-1].mark='2/127'

{%   if (interface.role == 'downstream'): %}
add firewall rule
set firewall.@rule[-1].name='Allow-pre-captive-{{ name }}'
set firewall.@rule[-1].src='{{ name }}'
set firewall.@rule[-1].dest='{{ ethernet.find_interface("upstream", interface.vlan.id) }}'
set firewall.@rule[-1].proto='any'
set firewall.@rule[-1].target='DROP'
set firewall.@rule[-1].mark='1/127'

add firewall include
set firewall.@include[-1].type=restore
set firewall.@include[-1].family=ipv4
set firewall.@include[-1].path='/usr/share/uspot/firewall.ipt'
set firewall.@include[-1].reload=1

add firewall include
set firewall.@include[-1].type=restore
set firewall.@include[-1].family=ipv6
set firewall.@include[-1].path='/usr/share/uspot/firewall.ipt'
set firewall.@include[-1].reload=1
{%   endif %}
{% endfor %}

add uhttpd uhttpd
set uhttpd.@uhttpd[-1].redirect_https='0'
set uhttpd.@uhttpd[-1].rfc1918_filter='1'
set uhttpd.@uhttpd[-1].max_requests='5'
set uhttpd.@uhttpd[-1].max_connections='100'
set uhttpd.@uhttpd[-1].cert='/etc/uhttpd.crt'
set uhttpd.@uhttpd[-1].key='/etc/uhttpd.key'
set uhttpd.@uhttpd[-1].script_timeout='60'
set uhttpd.@uhttpd[-1].network_timeout='30'
set uhttpd.@uhttpd[-1].http_keepalive='20'
set uhttpd.@uhttpd[-1].tcp_keepalive='1'
set uhttpd.@uhttpd[-1].no_dirlists='1'
add_list uhttpd.@uhttpd[-1].listen_http='0.0.0.0:80'
add_list uhttpd.@uhttpd[-1].listen_http='[::]:80'
set uhttpd.@uhttpd[-1].home=/tmp/ucentral/www-uspot
add_list uhttpd.@uhttpd[-1].ucode_prefix='/hotspot=/usr/share/uspot/handler.uc'
add_list uhttpd.@uhttpd[-1].ucode_prefix='/cpd=/usr/share/uspot/handler-cpd.uc'
add_list uhttpd.@uhttpd[-1].ucode_prefix='/env=/usr/share/uspot/handler-env.uc'
set uhttpd.@uhttpd[-1].error_page='/cpd'
