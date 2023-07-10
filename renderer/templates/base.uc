{%
let roles = (state.switch && state.switch.loop_detection &&
	     state.switch.loop_detection.roles) ?
			state.switch.loop_detection.roles : [];

services.set_enabled("ustpd", length(roles));

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

set network.up=device
set network.up.name=up
set network.up.type=bridge
set network.up.stp={{ loop_detect("upstream") }}
set network.up.igmp_snooping='1'

{% if (capab.platform != "switch"): %}
set network.down=device
set network.down.name=down
set network.down.type=bridge
set network.down.stp={{ loop_detect("downstream") }}
set network.down.igmp_snooping='1'

{% endif %}
set network.up_none=interface
set network.up_none.ifname=up
set network.up_none.proto=none

{% for (let k, v in capab.macaddr): %}
add network device
set network.@device[-1].name={{ s(k) }}
set network.@device[-1].macaddr={{ s(v) }}
{% endfor %}

{% for (let k, v in capab.switch): %}
add network switch
set network.@switch[-1].name={{ s(v.name) }}
set network.@switch[-1].reset={{ b(v.reset) }}
set network.@switch[-1].enable_vlan={{ b(v.enable) }}
{% endfor %}

{% for (let k, port in ethernet.ports): %}
{%   if (!port.switch) continue; %}
add network switch_vlan
set network.@switch_vlan[-1].device={{ s(port.switch.name) }}
set network.@switch_vlan[-1].vlan={{ s(port.vlan) }}
set network.@switch_vlan[-1].ports={{s(port.switch.port + 't ' + port.swconfig)}}
{% endfor %}
