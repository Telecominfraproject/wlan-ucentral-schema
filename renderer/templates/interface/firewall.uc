
add firewall zone
set firewall.@zone[-1].name={{ s(name) }}
{% if (interface.role == 'upstream'): %}
set firewall.@zone[-1].input='REJECT'
set firewall.@zone[-1].output='ACCEPT'
set firewall.@zone[-1].forward='REJECT'
set firewall.@zone[-1].masq=1
set firewall.@zone[-1].mtu_fix=1
{% else %}
set firewall.@zone[-1].input='REJECT'
set firewall.@zone[-1].output='ACCEPT'
set firewall.@zone[-1].forward='ACCEPT'

add firewall forwarding
set firewall.@forwarding[-1].src={{ s(name) }}
set firewall.@forwarding[-1].dest='{{ s(dest || ethernet.find_interface("upstream", interface.vlan.id)) }}'
{% endif %}
{% for (let network in networks || ethernet.calculate_names(interface)): %}
add_list firewall.@zone[-1].network={{ s(network) }}
{% endfor %}

add firewall rule
set firewall.@rule[-1].name='Allow-Ping'
set firewall.@rule[-1].src={{ s(name) }}
set firewall.@rule[-1].proto='icmp'
set firewall.@rule[-1].icmp_type='echo-request'
set firewall.@rule[-1].family='ipv4'
set firewall.@rule[-1].target='ACCEPT'

add firewall rule
set firewall.@rule[-1].name='Allow-IGMP'
set firewall.@rule[-1].src={{ s(name) }}
set firewall.@rule[-1].proto='igmp'
set firewall.@rule[-1].family='ipv4'
set firewall.@rule[-1].target='ACCEPT'


{% if (ipv4_mode || !ipv6_mode): %}
add firewall rule
set firewall.@rule[-1].name='Support-UDP-Traceroute'
set firewall.@rule[-1].src={{ s(name) }}
set firewall.@rule[-1].dest_port='33434:33689'
set firewall.@rule[-1].proto='udp'
set firewall.@rule[-1].family='ipv4'
set firewall.@rule[-1].target='REJECT'
set firewall.@rule[-1].enabled='false'

add firewall rule
set firewall.@rule[-1].name='Allow-DHCP-Renew'
set firewall.@rule[-1].src={{ s(name) }}
set firewall.@rule[-1].proto='udp'
set firewall.@rule[-1].dest_port='68'
set firewall.@rule[-1].target='ACCEPT'
set firewall.@rule[-1].family='ipv4'
{% endif %}

{%   if (ipv6_mode || !ipv4_mode): %}
add firewall rule
set firewall.@rule[-1].name='Allow-DHCPv6'
set firewall.@rule[-1].src={{ s(name) }}
set firewall.@rule[-1].proto='udp'
set firewall.@rule[-1].src_ip='fc00::/6'
set firewall.@rule[-1].dest_ip='fc00::/6'
set firewall.@rule[-1].dest_port='546'
set firewall.@rule[-1].family='ipv6'
set firewall.@rule[-1].target='ACCEPT'

add firewall rule
set firewall.@rule[-1].name='Allow-MLD'
set firewall.@rule[-1].src={{ s(name) }}
set firewall.@rule[-1].proto='icmp'
set firewall.@rule[-1].src_ip='fe80::/10'
set firewall.@rule[-1].icmp_type='130/0'
set firewall.@rule[-1].icmp_type='131/0'
set firewall.@rule[-1].icmp_type='132/0'
set firewall.@rule[-1].icmp_type='143/0'
set firewall.@rule[-1].family='ipv6'
set firewall.@rule[-1].target='ACCEPT'

add firewall rule
set firewall.@rule[-1].name='Allow-ICMPv6-Input'
set firewall.@rule[-1].src={{ s(name) }}
set firewall.@rule[-1].proto='icmp'
add_list firewall.@rule[-1].icmp_type='echo-request'
add_list firewall.@rule[-1].icmp_type='echo-reply'
add_list firewall.@rule[-1].icmp_type='destination-unreachable'
add_list firewall.@rule[-1].icmp_type='packet-too-big'
add_list firewall.@rule[-1].icmp_type='time-exceeded'
add_list firewall.@rule[-1].icmp_type='bad-header'
add_list firewall.@rule[-1].icmp_type='unknown-header-type'
add_list firewall.@rule[-1].icmp_type='router-solicitation'
add_list firewall.@rule[-1].icmp_type='neighbour-solicitation'
add_list firewall.@rule[-1].icmp_type='router-advertisement'
add_list firewall.@rule[-1].icmp_type='neighbour-advertisement'
set firewall.@rule[-1].limit='1000/sec'
set firewall.@rule[-1].family='ipv6'
set firewall.@rule[-1].target='ACCEPT'

add firewall rule
set firewall.@rule[-1].name='Allow-ICMPv6-Forward'
set firewall.@rule[-1].src={{ s(name) }}
set firewall.@rule[-1].dest='*'
set firewall.@rule[-1].proto='icmp'
add_list firewall.@rule[-1].icmp_type='echo-request'
add_list firewall.@rule[-1].icmp_type='echo-reply'
add_list firewall.@rule[-1].icmp_type='destination-unreachable'
add_list firewall.@rule[-1].icmp_type='packet-too-big'
add_list firewall.@rule[-1].icmp_type='time-exceeded'
add_list firewall.@rule[-1].icmp_type='bad-header'
add_list firewall.@rule[-1].icmp_type='unknown-header-type'
set firewall.@rule[-1].limit='1000/sec'
set firewall.@rule[-1].family='ipv6'
set firewall.@rule[-1].target='ACCEPT'
{% endif %}

{% if (interface.role == "downstream"): %}
add firewall rule
set firewall.@rule[-1].name='Allow-DNS-{{ name }}'
set firewall.@rule[-1].src={{ s(name) }}
set firewall.@rule[-1].dest_port='53'
set firewall.@rule[-1].family='ipv4'
add_list firewall.@rule[-1].proto='tcp'
add_list firewall.@rule[-1].proto='udp'
set firewall.@rule[-1].target='ACCEPT'

add firewall rule
set firewall.@rule[-1].name='Allow-DHCP-{{ name }}'
set firewall.@rule[-1].src={{ s(name) }}
set firewall.@rule[-1].dest_port=67
set firewall.@rule[-1].family='ipv4'
set firewall.@rule[-1].proto='udp'
set firewall.@rule[-1].target='ACCEPT'

add firewall rule
set firewall.@rule[-1].name='Allow-DHCPv6-{{ name }}'
set firewall.@rule[-1].src={{ s(name) }}
set firewall.@rule[-1].dest_port=547
set firewall.@rule[-1].family='ipv6'
set firewall.@rule[-1].proto='udp'
set firewall.@rule[-1].target='ACCEPT'
{% endif %}

{% if (interface.role == 'downstream' && interface?.ipv4?.disallow_upstream_subnet):
      for (let subnet in interface.ipv4.disallow_upstream_subnet):
%}
add firewall rule
set firewall.@rule[-1].name='Reject-{{ subnet }}-subnet-{{name}}'
set firewall.@rule[-1].src={{ s(name) }}
set firewall.@rule[-1].dest='{{ s(dest || ethernet.find_interface("upstream", interface.vlan.id)) }}'
set firewall.@rule[-1].dest_ip='{{ s(subnet) }}'
set firewall.@rule[-1].proto='all'
set firewall.@rule[-1].target='DROP'
{%    endfor
    endif %}
{%
	for (let forward in interface.ipv4?.port_forward)
		include('firewall/forward.uc', {
			forward,
			family: 'ipv4',
			source_zone: ethernet.find_interface('upstream', interface.vlan?.id),
			destination_zone: name,
			destination_subnet: interface.ipv4.subnet
		});

	for (let forward in interface.ipv6?.port_forward)
		include('firewall/forward.uc', {
			forward,
			family: 'ipv6',
			source_zone: ethernet.find_interface('upstream', interface.vlan?.id),
			destination_zone: name,
			destination_subnet: interface.ipv6.subnet
		});

	for (let allow in interface.ipv6?.traffic_allow)
		include('firewall/allow.uc', {
			allow,
			family: 'ipv6',
			source_zone: ethernet.find_interface('upstream', interface.vlan?.id),
			destination_zone: name,
			destination_subnet: interface.ipv6.subnet
		});
%}
