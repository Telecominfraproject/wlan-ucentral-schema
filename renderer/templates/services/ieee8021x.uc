{%
	if (!services.is_present("ieee8021x"))
		return;

	let enable = false; 
	for (let k, iface in state.interfaces)
		if (length(iface.ieee8021x_ports))
			enable = true;

	if (ieee8021x.mode == "radius") {
		if (!ieee8021x.radius?.auth_server_addr ||
		    !ieee8021x.radius?.auth_server_port ||
		    !ieee8021x.radius?.auth_server_secret) {
			warn('invalid radius configuration');
			enable = false;
		}
	}

	services.set_enabled("ieee8021x", enable);
	if (!enable)
		return;

	cursor.load("system");
	let certs = cursor.get_all("system", "@certificates[-1]");
%}
# IEEE8021x service configuration

add ieee8021x config 
set ieee8021x.@config[-1].ca={{ s(certs.ca) }}
set ieee8021x.@config[-1].cert={{ s(certs.cert) }}
set ieee8021x.@config[-1].key={{ s(certs.key) }}
{%	if (ieee8021x.mode == "radius"): %}
set ieee8021x.@config[-1].nas_identifier={{ s(ieee8021x.radius.nas_identifier) }}
set ieee8021x.@config[-1].auth_server_addr={{ s(ieee8021x.radius.auth_server_addr) }}
set ieee8021x.@config[-1].auth_server_port={{ s(ieee8021x.radius.auth_server_port) }}
set ieee8021x.@config[-1].auth_server_secret={{ s(ieee8021x.radius.auth_server_secret) }}
set ieee8021x.@config[-1].acct_server_addr={{ s(ieee8021x.radius.acct_server_addr) }}
set ieee8021x.@config[-1].acct_server_port={{ s(ieee8021x.radius.acct_server_port) }}
set ieee8021x.@config[-1].acct_server_secret={{ s(ieee8021x.radius.acct_server_secret) }}
set ieee8021x.@config[-1].coa_server_addr={{ s(ieee8021x.radius.coa_server_addr) }}
set ieee8021x.@config[-1].coa_server_port={{ s(ieee8021x.radius.coa_server_port) }}
set ieee8021x.@config[-1].coa_server_secret={{ s(ieee8021x.radius.coa_server_secret) }}
set ieee8021x.@config[-1].mac_address_bypass={{ b(ieee8021x.radius.mac_address_bypass) }}
{%	else
		files.add_named("/var/run/hostapd-ieee8021x.eap_user", render("../eap_users.uc", { users: ieee8021x.users }));
	endif
%}

