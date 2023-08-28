{% if (!services.is_present("ieee8021x")) return %}
{% let interfaces = services.lookup_interfaces("ieee8021x") %}
{% let enable = length(interfaces) %}
{% services.set_enabled("ieee8021x", enable) %}
{% if (!enable) return %}
{% let ports = [];
   for (let p in ieee8021x.port_filter)
	if (ethernet.ports[p])
		push(ports, ethernet.ports[p].netdev);
%}
# IEEE8021x service configuration

{% if(ieee8021x.mode == "radius"): %}
add ieee8021x radius
set ieee8021x.@radius[-1].nas_identifier={{ s(ieee8021x.radius.nas_identifier) }}
set ieee8021x.@radius[-1].auth_server_addr={{ s(ieee8021x.radius.auth_server_addr) }}
set ieee8021x.@radius[-1].auth_server_port={{ s(ieee8021x.radius.auth_server_port) }}
set ieee8021x.@radius[-1].auth_server_secret={{ s(ieee8021x.radius.auth_server_secret) }}
set ieee8021x.@radius[-1].acct_server_addr={{ s(ieee8021x.radius.acct_server_addr) }}
set ieee8021x.@radius[-1].acct_server_port={{ s(ieee8021x.radius.acct_server_port) }}
set ieee8021x.@radius[-1].acct_server_secret={{ s(ieee8021x.radius.acct_server_secret) }}
set ieee8021x.@radius[-1].coa_server_addr={{ s(ieee8021x.radius.coa_server_addr) }}
set ieee8021x.@radius[-1].coa_server_port={{ s(ieee8021x.radius.coa_server_port) }}
set ieee8021x.@radius[-1].coa_server_secret={{ s(ieee8021x.radius.coa_server_secret) }}
{% else %}
{% files.add_named("/var/run/hostapd-ieee8021x.eap_user", render("../eap_users.uc", { users: ieee8021x.users })) %}
{% endif %}

add ieee8021x certificates
{% if (ieee8021x.use_local_certificates): %}
{%   cursor.load("system") %}
{%   let certs = cursor.get_all("system", "@certificates[-1]") %}
set ieee8021x.@certificates[-1].ca={{ s(certs.ca) }}
set ieee8021x.@certificates[-1].cert={{ s(certs.cert) }}
set ieee8021x.@certificates[-1].key={{ s(certs.key) }}
{% else %}
set ieee8021x.@certificates[-1].ca={{ s(ieee8021x.ca_certificate) }}
set ieee8021x.@certificates[-1].cert={{ s(ieee8021x.server_certificate) }}
set ieee8021x.@certificates[-1].key={{ s(ieee8021x.private_key) }}
{% endif %}

{% for (let interface in interfaces): %}
{%   let name = ethernet.calculate_name(interface) %}
add ieee8021x network
set ieee8021x.@network[-1].network={{ name }}
{%  for (let port in ethernet.lookup_by_interface_spec(interface, ieee8021x.port_filter)): %}
{%	if (length(ports) && port in ports) continue; %}
add_list ieee8021x.@network[-1].ports={{ s(port) }}
{%  endfor %}
{%  for (let port in ethernet.lookup_by_interface_spec(interface, ieee8021x.port_filter)): %}
{%	if (length(ports) && port in ports) continue; %}
set network.{{ port }}=device
set network.@device[-1].name={{ s(port) }}
set network.@device[-1].auth='1'
{%  endfor %}
{% endfor %}
