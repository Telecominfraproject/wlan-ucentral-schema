{%
if (config.radius_gw_proxy)
	services.set_enabled("radius-gw-proxy", true);

function radius_proxy_tlv(server, port, name) {
	let tlv = replace(serial, /^(..)(..)(..)(..)(..)(..)$/, "$1$2$3$4$5$6") + sprintf(":%s:%s:%s", server, port, name);
	return tlv;
}

captive.interface(section, config);
let name = split(section, '_')[0];

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

if (captive.radius_gw_proxy)
	services.set_enabled("radius-gw-proxy", true);
%}

# Captive Portal service configuration

set uspot.{{ section }}=uspot
set uspot.{{ section }}.auth_mode={{ s(config.auth_mode) }}
set uspot.{{ section }}.web_root={{ b(config.web_root) }}
set uspot.{{ section }}.idle_timeout={{ config.idle_timeout }}
set uspot.{{ section }}.session_timeout={{ config.session_timeout }}

{% if (config.auth_mode in [ 'radius', 'uam']): %}
{%   if (config.radius_gw_proxy): %}
set uspot.{{ section }}.auth_server='127.0.0.1'
set uspot.{{ section }}.auth_port='1812'
set uspot.{{ section }}.auth_proxy={{ s(radius_proxy_tlv(config.auth_server, config.auth_port, 'captive')) }}
{%     if (config.acct_server): %}
set uspot.{{ section }}.acct_server='127.0.0.1'
set uspot.{{ section }}.acct_port='1813'
set uspot.{{ section }}.acct_proxy={{ s(radius_proxy_tlv(config.acct_server, config.acct_port, 'captive')) }}
{%     endif %}
{%   else %}
set uspot.{{ section }}.auth_server={{ s(config.auth_server) }}
set uspot.{{ section }}.auth_port={{ s(config.auth_port) }}
set uspot.{{ section }}.acct_server={{ s(config.acct_server) }}
set uspot.{{ section }}.acct_port={{ s(config.acct_port) }}
{%   endif %}
set uspot.{{ section }}.auth_secret={{ s(config.auth_secret) }}
set uspot.{{ section }}.acct_secret={{ s(config.acct_secret) }}
set uspot.{{ section }}.acct_interval={{ config.acct_interval }}
{% endif %}

{% if (config.auth_mode == 'credentials'): %}
{%   for (let cred in config.credentials): %}
add uspot credentials
set uspot.@credentials[-1].username={{ s(cred.username) }}
set uspot.@credentials[-1].password={{ s(cred.password) }}
set uspot.@credentials[-1].interface={{ s(section) }}
{%   endfor %}
{% endif %}

{% if (config.auth_mode == 'uam'): %}
{%
let math = require('math');
let challenge = "";
for (let i = 0; i < 16; i++)
	challenge += sprintf('%02x', math.rand() % 255);
%}
set uspot.{{ section }}.challenge={{ s(challenge) }}

set uspot.{{ section }}.uam_port={{ s(config.uam_port) }}
set uspot.{{ section }}.uam_secret={{ s(config.uam_secret) }}
set uspot.{{ section }}.uam_server={{ s(config.uam_server) }}
set uspot.{{ section }}.nasid={{ s(config.nasid) }}
set uspot.{{ section }}.nasmac={{ s(config.nasmac || serial) }}
set uspot.{{ section }}.ssid={{ s(config.ssid) }}
set uspot.{{ section }}.mac_format={{ s(config.mac_format) }}
set uspot.{{ section }}.final_redirect_url={{ s(config.final_redirect_url) }}
set uspot.{{ section }}.mac_auth={{ b(config.mac_auth) }}

set uhttpd.uam{{ config.uam_port }}=uhttpd
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
add_list uhttpd.@uhttpd[-1].listen_http='0.0.0.0:{{ config.uam_port }}'
add_list uhttpd.@uhttpd[-1].listen_http='[::]:{{ config.uam_port }}'
set uhttpd.@uhttpd[-1].home=/tmp/ucentral/www-uspot
add_list uhttpd.@uhttpd[-1].ucode_prefix='/logon=/usr/share/uspot/handler-uam.uc'
add_list uhttpd.@uhttpd[-1].ucode_prefix='/logoff=/usr/share/uspot/handler-uam.uc'
add_list uhttpd.@uhttpd[-1].ucode_prefix='/logout=/usr/share/uspot/handler-uam.uc'

set firewall.{{ name + config.uam_port}}_1=rule
set firewall.@rule[-1].name='Allow-UAM-{{ name }}'
set firewall.@rule[-1].src='{{ name }}'
set firewall.@rule[-1].dest_port='{{ config.uam_port }}'
set firewall.@rule[-1].proto='tcp'
set firewall.@rule[-1].target='ACCEPT'
set firewall.@rule[-1].mark='1/127'

set firewall.{{ name + config.uam_port}}_2=rule
set firewall.@rule[-1].name='Allow-UAM-{{ name }}'
set firewall.@rule[-1].src='{{ name }}'
set firewall.@rule[-1].dest_port='{{ config.uam_port }}'
set firewall.@rule[-1].proto='tcp'
set firewall.@rule[-1].target='ACCEPT'
set firewall.@rule[-1].mark='2/127'

{% endif %}
