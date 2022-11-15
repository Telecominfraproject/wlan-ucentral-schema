{%
if (!interface.tunnel.peer_address) {
        warn("A GRE tunnel requires a valid peer-address");
        return;
}
%}

# GRE Configuration
set network.greip6=interface
set network.greip6.proto='grev6tap'
set network.greip6.peer6addr='{{ interface.tunnel.peer_address }}'
set network.greip6.nohostroute='1'

{%
let suffix = '';
let cfg = {
	name: 'gretun6',
	netdev: 'gre6t-greip6',
	ipv4_mode, ipv4: interface.ipv4 || {},
	ipv6_mode, ipv6: interface.ipv6 || {}
};

if (ethernet.has_vlan(interface)) {
	cfg.name = 'gretun6_' + interface.vlan.id;
	cfg.netdev = 'gre6t-greip6.' + interface.vlan.id;
	cfg.this_vid = interface.vlan.id;
	suffix = '.' + interface.vlan.id;
}

include("common.uc", cfg);
%}

add firewall rule
set firewall.@rule[-1].target='ACCEPT'
set firewall.@rule[-1].src={{ s(name) }}
set firewall.@rule[-1].family='ipv6'
set firewall.@rule[-1].proto='47'
set firewall.@rule[-1].name='Allow-GREv6-{{ name }}'

add network device
set network.@device[-1].name={{ s(name) }}
set network.@device[-1].type='bridge'
set network.@device[-1].ports='gre6t-greip6{{ suffix }}'
set network.@device[-1].dhcp_healthcheck='{{ b(interface.tunnel.dhcp_healthcheck) }}'
