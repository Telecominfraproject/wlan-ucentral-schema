#!/usr/bin/ucode
push(REQUIRE_SEARCH_PATH,
	"/usr/lib/ucode/*.so",
	"/usr/share/ucentral/*.uc");

let ubus = require("ubus");
let fs = require("fs");

let boardfile = fs.open("/etc/board.json", "r");
let board = json(boardfile.read("all"));
boardfile.close();
let restrictfile = fs.open("/etc/ucentral/restrictions.json", "r");

capa = {};
if (restrictfile) {
	capa.restrictions = json(restrictfile.read("all")) || {};
	let pipe = fs.popen('fw_printenv developer');
	let developer = replace(pipe.read("all"), '\n', '');
	pipe.close();
	if (developer == 'developer=1')
		capa.restrictions.developer = true;
}
ctx = ubus.connect();
let wifi = require("wifi.phy");
capa.compatible = replace(board.model.id, ',', '_');
capa.model = board.model.name;

if (board.bridge && board.bridge.name == "switch")
	capa.platform = "switch";
else if (length(wifi))
	capa.platform = "ap";
else
	capa.platform = "unknown";

capa.network = {};
macs = {};
for (let k, v in board.network) {
	if (v.ports)
		capa.network[k] = v.ports;
	if (v.device)
		capa.network[k] = [v.device];
	if (v.ifname)
		capa.network[k] = split(replace(v.ifname, /^ */, ''), " ");
	if (v.macaddr)
		macs[k] = v.macaddr;
}

if (length(macs))
	capa.macaddr = macs;

if (board.wifi?.country)
	capa.country_code = board.wifi.country;

if (board.system?.label_macaddr)
	capa.label_macaddr = board.system?.label_macaddr;

if (board.switch)
	capa.switch = board.switch;
if (length(wifi))
	capa.wifi = wifi;

capafile = fs.open("/etc/ucentral/capabilities.json", "w");
capafile.write(capa);
capafile.close();
