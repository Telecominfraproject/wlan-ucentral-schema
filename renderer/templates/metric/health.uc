{%
	services.set_enabled("uhealth", true);
	if (!health)
		return;
%}

# Health configuration
set ustats.health.interval={{ health.interval }}
set ustats.health.dhcp_local={{ b(health.dhcp_local) }}
set ustats.health.dhcp_remote={{ b(health.dhcp_remote) }}
set ustats.health.dns_local={{ b(health.dns_local) }}
set ustats.health.dns_remote={{ b(health.dns_remote) }}
