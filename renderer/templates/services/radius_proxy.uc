{% if (!services.is_present("radsecproxy")) return %}
{% let enable = (length(radius_proxy) && length(radius_proxy.realms)) %}
{% services.set_enabled("radsecproxy", enable) %}
{% if (!enable) return %}

add radsecproxy options
add_list radsecproxy.@options[-1].ListenUDP='localhost:1812'
add_list radsecproxy.@options[-1].ListenUDP='localhost:1813'

add radsecproxy client
set radsecproxy.@client[-1].name='client'
set radsecproxy.@client[-1].host='localhost'
set radsecproxy.@client[-1].type='udp'
set radsecproxy.@client[-1].secret={{ s(radius_proxy.proxy_secret) }}

{% for (idx, realm in radius_proxy.realms): %}

{%   let certs = {};
     if (realm.use_local_certificates) {
	cursor.load("system");
	certs = cursor.get_all("system", "@certificates[-1]");
     } else if (realm.ca_certificate && realm.certificate && realm.private_key) {
	certs.ca = files.add_anonymous(location, 'ca' + idx, b64dec(realm.ca_certificate));
	certs.cert = files.add_anonymous(location, 'cert' + idx, b64dec(realm.certificate));
	certs.key = files.add_anonymous(location, 'key' + idx, b64dec(realm.private_key));
     } else if (realm.protocol == "radsec") {
	warn("invalid certificate settings");
	continue;
     }
%}

{%   if (realm.protocol == "radsec"): %}
set radsecproxy.tls{{ idx }}=tls
set radsecproxy.@tls[-1].name='tls{{ idx }}'
set radsecproxy.@tls[-1].CACertificateFile={{ s(certs.ca) }}
set radsecproxy.@tls[-1].certificateFile={{ s(certs.cert) }}
set radsecproxy.@tls[-1].certificateKeyFile={{ s(certs.key) }}
set radsecproxy.@tls[-1].certificateKeyPassword=''

set radsecproxy.server{{ idx }}=server
set radsecproxy.@server[-1].name='server{{ idx }}'
{%     if (realm.auto_discover): %}
set radsecproxy.@server[-1].dynamicLookupCommand='/usr/libexec/naptr_lookup.sh'
{%     else %}
set radsecproxy.@server[-1].host={{ s(realm.host) }}
set radsecproxy.@server[-1].port={{ s(realm.port) }}
set radsecproxy.@server[-1].secret={{ s(realm.secret) }}
{%     endif %}
set radsecproxy.@server[-1].type='tls'
set radsecproxy.@server[-1].tls='tls{{ idx }}'
set radsecproxy.@server[-1].statusServer='0'
set radsecproxy.@server[-1].certificateNameCheck='0'
{%     for (name in realm.realm): %}
add radsecproxy realm
set radsecproxy.@realm[-1].name='{{ name }}'
set radsecproxy.@realm[-1].server='server{{ idx }}'
set radsecproxy.@realm[-1].accountingServer='server{{ idx }}'
{%     endfor %}
{%   endif %}

{%   if (realm.protocol == "radius"): %}
set radsecproxy.server{{ idx + "auth" }}=server
set radsecproxy.@server[-1].name='server{{ idx }}auth'
set radsecproxy.@server[-1].host={{ s(realm.auth_server) }}
set radsecproxy.@server[-1].port={{ s(realm.auth_port) }}
set radsecproxy.@server[-1].secret={{ s(realm.auth_secret) }}
set radsecproxy.@server[-1].type='udp'
{%     if (realm.acct_server): %}
set radsecproxy.server{{ idx + "acct" }}=server
set radsecproxy.@server[-1].name='server{{ idx }}acct'
set radsecproxy.@server[-1].host={{ s(realm.acct_server) }}
set radsecproxy.@server[-1].port={{ s(realm.acct_port) }}
set radsecproxy.@server[-1].secret={{ s(realm.acct_secret) }}
set radsecproxy.@server[-1].type='udp'
{%     endif %}
{%     for (name in realm.realm): %}
add radsecproxy realm
set radsecproxy.@realm[-1].name='{{ name }}'
set radsecproxy.@realm[-1].server='server{{ idx }}auth'
{%       if (realm.acct_server): %}
set radsecproxy.@realm[-1].accountingServer='server{{ idx }}acct'
{%       endif %}
{%     endfor %}
{%   endif %}

{%   if (realm.protocol == "block"): %}
{%     for (name in realm.realm): %}
add radsecproxy realm
set radsecproxy.@realm[-1].name='{{ name }}'
set radsecproxy.@realm[-1].replyMessage={{ s(realm.message) }}
{%     endfor %}
{%   endif %}
{% endfor %}
