{% if (interface.broad_band.protocol == 'wwan'): %}
{%
function match_pdptype() {
	let pdptypes = {
		'ipv4': 'ip',
		'ipv6': 'ipv6',
		'dual-stack': 'ipv4v6'
	};
	return pdptypes[interface.broad_band.packet_data_protocol];
}

function match_authtype() {
	if (interface.broad_band.authentication_type == 'papchap')
		return 'both';
	return interface.broad_band.authentication_type;
}
%}

set network.{{ name }}=interface
set network.{{ name }}.ucentral_name={{ s(interface.name) }}
set network.{{ name }}.ucentral_path={{ s(location) }}
set network.{{ name }}.proto={{ s(interface.broad_band.modem_type) }}
set network.{{ name }}.pincode={{ s(interface.broad_band.pin_code) }}
set network.{{ name }}.apn={{ s(interface.broad_band.access_point_name) }}
set network.{{ name }}.device='/dev/cdc-wdm0'
set network.{{ name }}.pdptype={{ s(match_pdptype()) }}
set network.{{ name }}.auth={{ s(match_authtype()) }}
set network.{{ name }}.username={{ s(interface.broad_band.user_name) }}
set network.{{ name }}.password={{ s(interface.broad_band.password) }}
{%
/* interface.uc hands a broad-band uplink straight to this template and
 * returns, so interface/common.uc - the only template that emits
 * network.<iface>.metric - never runs for it. netifd then treats the route as
 * metric 0, which beats the default of 5 that interface.uc gives every other
 * upstream interface, so an LTE route won even while the modem could not
 * carry traffic. The value itself was already decided by broadband.uc
 * (uplink.metric = 1); this only makes it reach uci. */
%}
set network.{{ name }}.metric={{ interface.metric }}
{% endif %}

{% if (interface.broad_band.protocol == 'pppoe'): %}

set network.{{ name }}=interface
set network.{{ name }}.ucentral_name={{ s(interface.name) }}
set network.{{ name }}.ucentral_path={{ s(location) }}
set network.{{ name }}.ifname={{ s(keys(eth_ports)[0]) }}
set network.{{ name }}.proto='pppoe'
set network.{{ name }}.username={{ s(interface.broad_band.user_name) }}
set network.{{ name }}.password={{ s(interface.broad_band.password) }}
set network.{{ name }}.timeout={{ s(interface.broad_band.timeout) }}
set network.{{ name }}.metric={{ interface.metric }}
{% endif %}


{% include('firewall.uc', { name, ipv4: true, ipv6: true }); %}
