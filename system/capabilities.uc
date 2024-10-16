#!/usr/bin/ucode
push(REQUIRE_SEARCH_PATH,
	"/usr/lib/ucode/*.so",
	"/usr/share/ucentral/*.uc");

let ubus = require("ubus");
let fs = require("fs");
let default_config = {
	country: 'US'
};
let boardfile = fs.open("/etc/board.json", "r");
let board = json(boardfile.read("all"));
boardfile.close();
let restrictfile = fs.open("/etc/ucentral/restrictions.json", "r");

capa = {
	'secure-rtty': true,
	'default-config': true,
};
if (restrictfile) {
	capa.restrictions = json(restrictfile.read("all")) || {};
	let pipe = fs.popen('fw_printenv developer');
	let developer = replace(pipe.read("all"), '\n', '');
	pipe.close();
	if (developer == 'developer=1')
		capa.developer = true;
	else
		capa.developer = false;
}

let version = json(fs.readfile('/etc/ucentral/version.json') || '{}');
let schema = json(fs.readfile('/etc/ucentral/schema.json') || '{}');
let version_vendor = json(fs.readfile('/etc/ucentral/version.vendor.json') || '{}');
let schema_vendor = json(fs.readfile('/etc/ucentral/schema.vendor.json') || '{}');

if (length(version_vendor))
	version.vendor = version_vendor;

if (length(schema_vendor))
	schema.vendor = schema_vendor;

ctx = ubus.connect();

if (board.wifi?.country) {
	let countries = split(board.wifi.country, ' ');
	default_config.country = countries[0];
	capa.country_codes = countries;
} 

if (fs.stat('/tmp/squashfs')) {
	let pipe = fs.popen('fw_printenv -n country');
	let country = replace(pipe.read("all"), '\n', '');
	pipe.close();
	if (country)
		default_config.country = country;
	else
		system('fw_setenv country ' + default_config.country); 
	fs.writefile('/etc/ucentral/ucentral.defaults', default_config);
} else {
	if (!fs.stat('/certificates/ucentral.defaults')) {
		fs.writefile('/certificates/ucentral.defaults', default_config);
	}
	if (fs.stat('/certificates/ucentral.defaults')) {
		let defaults = fs.readfile('/certificates/ucentral.defaults');
		if (json(defaults))
			default_config = json(defaults);
	}
	fs.writefile('/etc/ucentral/ucentral.defaults', default_config);
}
capa.country = default_config.country || 'US';

let wifi = require("wifi.phy");

capa.compatible = replace(board.model.id, ',', '_');
capa.model = board.model.name;

capa.version = {
	'ap': version,
	schema
};

if (board.bridge && board.bridge.name == "switch")
	capa.platform = "switch";
else if (length(wifi))
	capa.platform = "ap";
else
	capa.platform = "unknown";

if (board.switch) {
	capa.switch = [];
	capa.switch_ports = {};
	for (let name, s in board.switch) {
		let device = { name, lan: [], wan: [] };
		let netdev;
		for (let p in s.ports) {
			if (p.device) {
				netdev = p.device;
				device.port = p.num;
			} else if (device[p.role]) {
				push(device[p.role], p.num)
			}
		}
		if (!length(device.lan))
			delete device.lan;
		if (!length(device.wan))
			delete device.wan;
		if (netdev)
			capa.switch_ports[netdev] = device;
		push(capa.switch, { name, enable: s.enable, reset: s.reset });
	}
}

function swconfig_ports(device, role) {
	let netdev = split(device, '.')[0];
	let switch_dev = capa.switch_ports ? capa.switch_ports[netdev] : null;
	if (!switch_dev || !switch_dev[role])
		return [ device ];
	let rv = [];
	for (let port in switch_dev[role])
		push(rv, netdev + ':' + port);
	return rv;
}

capa.network = {};
macs = {};
for (let k, v in board.network) {
	if (v.ports)
		capa.network[k] = v.ports;
	if (v.device)
		capa.network[k] = swconfig_ports(v.device, k);
	if (v.ifname)
		capa.network[k] = split(replace(v.ifname, /^ */, ''), " ");
	if (v.macaddr)
		macs[k] = v.macaddr;
}

if (length(macs))
	capa.macaddr = macs;

if (board.system?.label_macaddr)
	capa.label_macaddr = board.system?.label_macaddr;

if (length(wifi))
	capa.wifi = wifi;

capa.compress_cmd = true;

fs.writefile('/etc/ucentral/capabilities.json', capa);

