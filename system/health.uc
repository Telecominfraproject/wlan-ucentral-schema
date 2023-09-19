#!/usr/bin/ucode
push(REQUIRE_SEARCH_PATH, '/usr/share/ucentral/*.uc');
let fs = require('fs');
let uci = require('uci');
let ubus = require('ubus');

state = {
	unit: {},
	interfaces: {}
};

let ctx = ubus.connect();
let interfaces = ctx.call('network.interface', 'dump').interface;
let cursor = uci.cursor();
cursor.load('health');
cursor.load('dhcp');
cursor.load('network');
cursor.load('wireless');
let config = cursor.get_all('state', 'health');
let dhcp = cursor.get_all('dhcp');
let wifi_config = cursor.get_all('wireless');
let wifi_state = require('wifi.iface');
let count = 0;

function find_ssid(ssid) {
	for (let name, iface in wifi_state)
		if (ssid == iface.ssid)
			return 0;
	return 1;
}

function radius_probe(server, port, secret, user, pass)
{
	let f = fs.open('/tmp/radius.conf', 'w');
	if (f) {
		f.write(sprintf('authserver %s:%d\n', server, port));
		f.write('servers /tmp/radius.servers\n');
		f.write('dictionary /etc/radcli/dictionary\n');
		f.write('radius_timeout 3\n');
		f.write('radius_retries 1\n');
		f.write('bindaddr *\n');
		f.close();
	}

	let f = fs.open('/tmp/radius.servers', 'w');
	if (f) {
		f.write(sprintf('%s %s\n', server, secret));
		f.close();
	}
	return system(['/usr/sbin/radiusprobe', user, pass]);
}

for (let iface in interfaces) {
	let name = iface.interface;
	if (name == 'loopback')
		continue;

	count++;

	let health = {};
	let ssid = {};
	let radius = {};
	let device = iface.l3_device || iface.interface;
	let warnings = [];

	let probe_dhcp = cursor.get('network', iface.interface, 'dhcp_healthcheck') || false;

	if (dhcp[name]?.leasetime && +config.dhcp_local)
		probe_dhcp = true;

	if (iface?.data.leasetime && +config.dhcp_remote)
		probe_dhcp = true;

	if (probe_dhcp) {
		let rc = system(['/usr/sbin/dhcpdiscover', '-i', device, '-t', '5']);
		if (rc) {
			health.dhcp = false;
			push(warnings, 'DHCP did not offer any leases');
			ctx.call('event', 'event',  { object: 'health', verb: 'dhcp', payload: { iface: name, error: 'DHCP did not offer any leases' }});
		}
	}

	let probe_dns = false;

	if (length(iface['dns-server']) && +config.dns_remote)
		probe_dns = true;

	if (dhcp[name]?.dns_service && +config.dns_local)
                probe_dns = true;

	if (probe_dns) {
		let dns = iface['dns-server'];
		if (!length(dns) && iface['ipv4-address'] && iface['ipv4-address'][0])
			dns = [ iface['ipv4-address'][0]['address'] ];

		for (let ip in dns) {
			let rc = system(['/usr/sbin/dnsprobe', '-s', ip]);

			if (rc) {
				health.dns = false;
				push(warnings, `DNS ${ip} is not reachable`);
				ctx.call('event', 'event',  { object: 'health', verb: 'dns', payload: { iface: name, error: `DNS ${ip} is not reachable.` }});
			}
		}
	}

	for (let k, iface in wifi_config) {
		if (iface['.type'] != 'wifi-iface' || iface.network != name)
			continue;
		if (find_ssid(iface.ssid))
			ssid[iface.ssid] = false;
		if (iface.auth_server && iface.auth_port && iface.auth_secret && iface.health_username && iface.health_password && !iface.radius_gw_proxy)
			if (radius_probe(iface.auth_server, iface.auth_port, iface.auth_secret, iface.health_username, iface.health_password)) {
				radius[iface.ssid] = false;
				push(warnings, sprintf('Radius %s:%s is not reachable', iface.auth_server, iface.auth_port));
				ctx.call('event', 'event',  { object: 'health', verb: 'radius', payload: { ssid: iface.ssid, error: `Radius ${iface.auth_server}:${iface.auth_port} is not reachable` }});
			}
	}

	if (length(ssid))
		health.ssids = ssid;

	if (length(radius))
		health.radius = radius;

	if (length(health)) {
		health.location= cursor.get('network', name, 'ucentral_path');
		if (length(warnings))
			health.warning = warnings;
		state.interfaces[name] = health;
	}
}

try {
	memory = ctx.call('system', 'info');
	memory = memory.memory;
	state.unit.memory =  100 - (memory.available * 100 / memory.total);
	if (state.unit.memory >= 90)
		ctx.call('event', 'event',  { object: 'health', verb: 'memory', payload: { used: state.unit.memory, error: 'Memory is almost exhausted.' }});
}
catch(e) {
	log('Failed to invoke memory probing: %s\n', e);
}

let errors = length(state.interfaces);
if (!errors)
	delete state.interfaces;

let sanity = 100 - (errors * 100 / count);

warn(printf('health check reports sanity of %d', sanity));
ctx.call('ucentral', 'health', {sanity: sanity, data: state});
