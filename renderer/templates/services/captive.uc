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

if (!captive.web_root)
	system('cp -r /www-uspot /tmp/ucentral/');
else {
	let fs = require('fs');
	fs.mkdir('/tmp/ucentral/www-uspot');
	let web_root = fs.open('/tmp/ucentral/web-root.tar', 'w');
	web_root.write(b64dec(captive.web_root));
	web_root.close();
	system('tar x -C /tmp/ucentral/www-uspot -f /tmp/ucentral/web-root.tar');
}
%}

# Captive Portal service configuration

set uspot.config.auth_mode={{ s(captive.auth_mode) }}
set uspot.config.web_root={{ b(captive.web_root) }}
set uspot.config.idle_timeout={{ captive.idle_timeout }}
set uspot.config.session_timeout={{ captive.session_timeout }}

{% if (captive.auth_mode in [ 'radius', 'uam']): %}
set uspot.radius.auth_server={{ s(captive.auth_server) }}
set uspot.radius.auth_port={{ s(captive.auth_port) }}
set uspot.radius.auth_secret={{ s(captive.auth_secret) }}
set uspot.radius.acct_server={{ s(captive.acct_server) }}
set uspot.radius.acct_port={{ s(captive.acct_port) }}
set uspot.radius.acct_secret={{ s(captive.acct_secret) }}
set uspot.radius.acct_interval={{ captive.acct_interval }}
{% endif %}

{% if (captive.auth_mode == 'uam'): %}
set uspot.uam.uam_port={{ s(captive.uam_port) }}
set uspot.uam.uam_secret={{ s(captive.uam_secret) }}
set uspot.uam.uam_server={{ s(captive.uam_server) }}
set uspot.uam.nasid={{ s(captive.nasid) }}
set uspot.uam.nasmac={{ s(captive.nasmac || serial) }}
set uspot.uam.ssid={{ s(captive.ssid) }}
set uspot.uam.mac_format={{ s(captive.mac_format) }}
set uspot.uam.final_redirect_url={{ s(captive.final_redirect_url) }}

{%
let math = require('math');
let challenge = "";
for (let i = 0; i < 16; i++)
        challenge += sprintf('%02x', math.rand() % 255);
%}
set uspot.uam.challenge={{ s(challenge) }}

{% endif %}

{% if (captive.auth_mode == 'credentials'): %}
{%   for (let cred in captive.credentials): %}
add uspot credentials
set uspot.@credentials[-1].username={{ s(cred.username) }}
set uspot.@credentials[-1].password={{ s(cred.password) }}
{%   endfor %}
{% endif %}

{% for (let interface in interfaces): %}
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

{%   if (captive.auth_mode == 'uam'): %}
add firewall rule
set firewall.@rule[-1].name='Allow-UAM-{{ name }}'
set firewall.@rule[-1].src='{{ name }}'
set firewall.@rule[-1].dest_port='{{ captive.uam_port }}'
set firewall.@rule[-1].proto='tcp'
set firewall.@rule[-1].target='ACCEPT'
set firewall.@rule[-1].mark='1/127'

add firewall rule
set firewall.@rule[-1].name='Allow-UAM-{{ name }}'
set firewall.@rule[-1].src='{{ name }}'
set firewall.@rule[-1].dest_port='{{ captive.uam_port }}'
set firewall.@rule[-1].proto='tcp'
set firewall.@rule[-1].target='ACCEPT'
set firewall.@rule[-1].mark='2/127'
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
add_list uhttpd.@uhttpd[-1].listen_http='0.0.0.0:80'
add_list uhttpd.@uhttpd[-1].listen_http='[::]:80'
set uhttpd.@uhttpd[-1].home=/tmp/ucentral/www-uspot
add_list uhttpd.@uhttpd[-1].ucode_prefix='/hotspot=/usr/share/uspot/handler.uc'
add_list uhttpd.@uhttpd[-1].ucode_prefix='/cpd=/usr/share/uspot/handler-cpd.uc'
add_list uhttpd.@uhttpd[-1].ucode_prefix='/env=/usr/share/uspot/handler-env.uc'
set uhttpd.@uhttpd[-1].error_page='/cpd'


{% if (captive.auth_mode == 'uam'): %}
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
add_list uhttpd.@uhttpd[-1].listen_http='0.0.0.0:{{ captive.uam_port }}'
add_list uhttpd.@uhttpd[-1].listen_http='[::]:{{ captive.uam_port }}'
set uhttpd.@uhttpd[-1].home=/tmp/ucentral/www-uspot
add_list uhttpd.@uhttpd[-1].ucode_prefix='/logon=/usr/share/uspot/handler-uam.uc'
add_list uhttpd.@uhttpd[-1].ucode_prefix='/logoff=/usr/share/uspot/handler-uam.uc'
{% endif %}
