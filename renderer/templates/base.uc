{%
let board = fs.readfile('/etc/board.json');
if (board)
	board = json(board);
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
set network.up.igmp_snooping='1'
set network.up.macaddr={{ s(capab.macaddr?.wan) }}

{% if (capab.platform != "switch"): %}
set network.down=device
set network.down.name=down
set network.down.type=bridge
set network.down.igmp_snooping='1'
set network.down.macaddr={{ s(capab.macaddr?.lan) }}

{% endif %}
set network.up_none=interface
set network.up_none.ifname=up
set network.up_none.proto=none

{% for (let k, v in capab.switch): %}
add network switch
set network.@switch[-1].name={{ s(v.name) }}
set network.@switch[-1].reset={{ b(v.reset) }}
set network.@switch[-1].enable_vlan={{ b(v.enable) }}
{% endfor %}

{% for (let k, v in board?.network):
	if (+v.none == 1): %}
set network.{{v.device}}_none=interface
set network.{{v.device}}_none.proto=none
set network.{{v.device}}_none.device={{ s(v.device) }}
{% 	endif
endfor %}
