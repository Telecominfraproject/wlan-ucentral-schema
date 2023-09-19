{%
	if (!health)
		return;
%}

# Health configuration
set state.health.interval={{ health.interval }}
set state.health.dhcp_local={{ b(health.dhcp_local) }}
set state.health.dhcp_remote={{ b(health.dhcp_remote) }}
set state.health.dns_local={{ b(health.dns_local) }}
set state.health.dns_remote={{ b(health.dns_remote) }}
