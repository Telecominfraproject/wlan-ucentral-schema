{%
let roles = (state.switch && state.switch.loop_detection &&
	     state.switch.loop_detection.roles) ?
			state.switch.loop_detection.roles : [];

function loop_detect(role) {
	return (index(roles, role) >= 0) ? 1 : 0;
}
%}

# Basic configuration
set network.loopback=interface
set network.loopback.ifname='lo'
set network.loopback.proto='static'
set network.loopback.ipaddr='127.0.0.1'
set network.loopback.netmask='255.0.0.0'

add network device
set network.@device[-1].name=up
set network.@device[-1].type=bridge
set network.@device[-1].stp={{ loop_detect("upstream") }}
set network.@device[-1].igmp_snooping='1'

{% if (capab.platform != "switch"): %}
add network device
set network.@device[-1].name=down
set network.@device[-1].type=bridge
set network.@device[-1].stp={{ loop_detect("downstream") }}
set network.@device[-1].igmp_snooping='1'

{% endif %}
set network.up_none=interface
set network.up_none.ifname=up
set network.up_none.proto=none

{% for (let k, v in capab.macaddr): %}
add network device
set network.@device[-1].name={{ s(k) }}
set network.@device[-1].macaddr={{ s(v) }}
{% endfor %}
