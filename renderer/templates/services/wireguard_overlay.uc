{%
let wireguard = length(services.lookup_interfaces("wireguard-overlay"));
let vxlan = length(services.lookup_interfaces("vxlan-overlay"));

if (!wireguard && !vxlan) {
	services.set_enabled("unetd", false);
	return;
}

if (wireguard + vlxan > 1) {
	warn('only a single wireguard/vxlan-overlay is allowed\n');
	services.set_enabled("unetd", false);
	return;
}

if (!wireguard_overlay.root_node.key ||
    !wireguard_overlay.root_node.endpoint ||
    !wireguard_overlay.root_node.ipaddr) {
	warn('root node is not configured correctly\n');
	services.set_enabled("unetd", false);
	return;
}

services.set_enabled("unetd", true);

let ips = [];

wireguard_overlay.root_node.name = "gateway";
wireguard_overlay.root_node.groups = [ "gateway" ];

for (let ip in wireguard_overlay.root_node.ipaddr)
	push(ips, ip);

if (wireguard)
	wireguard_overlay.root_node.subnet = [ '0.0.0.0/0' ];

latency.add(wireguard_overlay.root_node.endpoint, 4);

let cfg = {
	'config': {
		'port': wireguard_overlay.peer_port,
		'peer-exchange-port': wireguard_overlay.peer_exchange_port,
		'keepalive': 10
	},
	'hosts': {
		gateway: wireguard_overlay.root_node,
	}
};

let pipe = require('fs').popen(sprintf('echo "%s" | wg pubkey', wireguard_overlay.private_key));
let pubkey = replace(pipe.read("all"), '\n', '');
pipe.close();
for (let host in wireguard_overlay.hosts)
	if (host.name) {
		if (!host.name || !host.key) {
			warn('host is not configured correctly\n');
			return;
		}

		cfg.hosts[host.name] = host;
		cfg.hosts[host.name].groups = [ 'ap' ];
		if (host.key == pubkey)
			continue;
		for (let ip in host.ipaddr)
			push(ips, ip);
	}
if (vxlan) {
	cfg.services = {
		"l2-tunnel": {
			"type": "vxlan",
			"config": {
				port: wireguard_overlay?.vxlan?.port || 4789,
			},
			"members": [ "gateway", "@ap" ]
		}
	};

	if (wireguard_overlay?.vxlan?.isolate ?? true)
		cfg.services['l2-tunnel'].config.forward_ports = [ "gateway" ];
}

system('rm /tmp/unet.*.json');
let filename = '/tmp/unet.' + time() + '.json';

files.add_named(filename, cfg);

include('../interface/firewall.uc', { name: 'unet', ipv4_mode: true, ipv6_mode: true, interface: { role: 'upstream' }, networks: [ 'unet' ] });
%}


# Wireguard Overlay Configuration
set network.unet=interface
set network.unet.proto=unet
set network.unet.device=unet
set network.unet.file={{ s(filename) }}
set network.unet.key={{ s(wireguard_overlay.private_key) }}
set network.unet.domain=unet
set network.unet.ip4table='{{ routing_table.get('wireguard_overlay') }}'
{% if (vxlan): %}
set network.unet.tunnels='vx-unet=l2-tunnel'

add firewall rule
set firewall.@rule[-1].name='Allow-VXLAN-unet'
set firewall.@rule[-1].src='unet'
set firewall.@rule[-1].proto='udp'
set firewall.@rule[-1].target='ACCEPT'
set firewall.@rule[-1].dest_port={{ wireguard_overlay?.vxlan?.port || 3457 }}
{% endif %}

{% for (let ip in ips): %}
add network route
set network.@route[-1].interface='unet'
set network.@route[-1].target={{ s(ip) }}
set network.@route[-1].table='local'
{% latency.add(ip, 4) %}
{% endfor %}
