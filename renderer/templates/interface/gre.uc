{%
if (!ethernet.has_vlan(interface)) {
        warn("A GRE tunnel can only be created with a valid VLAN ID");
        return;
}
if (!interface.tunnel.peer_address) {
        warn("A GRE tunnel requires a valid peer-address");
        return;
}
%}

# GRE Configuration
set network.gre=interface
set network.gre.proto='gretap'
set network.gre.type='gre'
set network.gre.peeraddr='{{ interface.tunnel.peer_address }}'

{%
include("common.uc", {
	name: 'gretun_' + interface.vlan.id,
	netdev: 'gre4t-gre.' + interface.vlan.id,
	this_vid: interface.vlan.id,
	ipv4_mode, ipv4: interface.ipv4 || {},
	ipv6_mode, ipv6: interface.ipv6 || {}
});
%}

set network.gre_{{ interface.vlan.id }}=interface
set network.gre_{{ interface.vlan.id }}.ifname='gre.{{ interface.vlan.id }}'
set network.gre_{{ interface.vlan.id }}.mtu='1500'

add network device
set network.@device[-1].name={{ s(name) }}
set network.@device[-1].type='bridge'
set network.@device[-1].ports='gre4t-gre.{{ interface.vlan.id }}'
