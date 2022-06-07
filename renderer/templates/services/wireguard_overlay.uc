{%
let cfg = {
	'config': {
		'port': wireguard_overlay.peer_port,
		'peer-exchange-port': wireguard_overlay.peer_exchange_port,
		'keepalive': 10
	},
	'hosts': {

	}
};

let pipe = require('fs').popen(sprintf('echo "%s" | wg pubkey', wireguard_overlay.private_key));
let pubkey = replace(pipe.read("all"), '\n', '');
pipe.close();
let ips = [];
for (let host in wireguard_overlay.hosts)
	if (host.name) {
		cfg.hosts[host.name] = host;
		if (host.key == pubkey)
			continue;
		for (let ip in host.ipaddr)
			push(ips, ip);
	}
files.add_named('/tmp/unet.json', cfg);

include('../interface/firewall.uc', { name: 'unet', ipv4_mode: true, ipv6_mode: true, interface: { role: 'upstream' }, networks: [ 'unet' ] });
%}


# Wireguard Overlay Configuration
set network.unet=interface
set network.unet.proto=unet
set network.unet.device=unet
set network.unet.file='/tmp/unet.json'
set network.unet.key={{ s(wireguard_overlay.private_key) }}
set network.unet.domain=unet
set network.unet.ip4table='{{ routing_table.get('wireguard_overlay') }}'

{% for (let ip in ips): %}
add network route
set network.@route[-1].interface='unet'
set network.@route[-1].target={{ s(ip) }}
set network.@route[-1].table='local'
{% endfor %}
