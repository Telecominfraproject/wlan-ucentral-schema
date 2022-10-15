{% if (!length(health_check))
	health_check = {
		dhcp_local: 1,
		dhcp_remote: 0,
		dns_local: 1,
		dns_remote: 1,
	};
%}
set health.config.dhcp_local={{ b(health_check.dhcp_local) }}
set health.config.dhcp_remote={{ b(health_check.dhcp_remote) }}
set health.config.dns_local={{ b(health_check.dns_local) }}
set health.config.dns_remote={{ b(health_check.dns_remote) }}
