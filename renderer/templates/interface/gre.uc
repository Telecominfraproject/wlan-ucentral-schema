{%
if (!interface.tunnel.peer_address) {
        warn("A GRE tunnel requires a valid peer-address");
        return;
}
%}

# GRE Configuration
set network.gre=interface
set network.gre.proto='gretap'
set network.gre.peeraddr='{{ interface.tunnel.peer_address }}'
set network.gre.nohostroute='1'
set network.gre.df='{{ b(interface.tunnel.dont_fragment) }}'

{%
let suffix = '';
let cfg = {
	name: 'gretun',
	netdev: 'gre4t-gre',
	ipv4_mode, ipv4: interface.ipv4 || {},
	ipv6_mode, ipv6: interface.ipv6 || {}
};

if (ethernet.has_vlan(interface)) {
	cfg.name = 'gretun_' + interface.vlan.id;
	cfg.netdev = 'gre4t-gre.' + interface.vlan.id;
	cfg.this_vid = interface.vlan.id;
	suffix = '.' + interface.vlan.id;
}

include("common.uc", cfg);
%}

add firewall rule
set firewall.@rule[-1].target='ACCEPT'
set firewall.@rule[-1].src={{ s(name) }}
set firewall.@rule[-1].family='ipv4'
set firewall.@rule[-1].proto='47'
set firewall.@rule[-1].name='Allow-GRE-{{ name }}'

add network device
set network.@device[-1].name={{ s(name) }}
set network.@device[-1].type='bridge'
set network.@device[-1].ports='gre4t-gre{{ suffix }}'
set network.@device[-1].dhcp_healthcheck='{{ b(interface.tunnel.dhcp_healthcheck) }}'
