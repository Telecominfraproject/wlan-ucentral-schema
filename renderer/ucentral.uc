#!/usr/bin/ucode
REQUIRE_SEARCH_PATH = [
	"/usr/lib/ucode/*.so",
	"/usr/share/ucentral/*.uc",
	...REQUIRE_SEARCH_PATH
];

import * as schemareader from 'schemareader';
let renderer = require("renderer");
let fs = require("fs");
let uci = require("uci");
let ubus = require("ubus").connect();

let inputfile = fs.open(ARGV[0], "r");
let inputjson = json(inputfile.read("all"));
let custom_config = (split(ARGV[0], ".")[0] != "/etc/ucentral/ucentral");

let error = 0;

inputfile.close();
let logs = [];

function wait_wireless_ready() {
	for (let i = 0; i < 30; i++) {
		let status = ubus.call('network.wireless', 'status');
		if (!status)
			return;
		let pending = false;
		for (let name, radio in status)
			if (radio?.pending) {
				pending = true;
				break;
			}
		if (!pending)
			return;
		sleep(1000);
	}
	warn("ucentral: timeout waiting for network.wireless to settle\n");
}

// netifd restarts wg0 only when its interface section changes, so a peer
// change (allowed-ips, endpoint, keys) needs an explicit restart; returns
// the committed peers of wg0, or null when wg0 is not configured
function wireguard_peers() {
	let cursor = uci.cursor();
	if (cursor.get('network', 'wg0') != 'interface')
		return null;

	let peers = [];
	cursor.foreach('network', 'wireguard_wg0', (s) => {
		let peer = {};
		for (let k, v in s)
			if (substr(k, 0, 1) != '.')
				peer[k] = v;
		push(peers, peer);
	});

	return sprintf('%J', peers);
}

function set_service_state(state) {
	let services = ubus.call('service', 'list');
	for (let service, enable in renderer.services_state()) {
		if (enable != state)
			continue;
		if (enable == 'no-restart')
			if (services[service] && services[service]?.instances[service]?.running) {
				printf("%s is already running\n", service);
				continue;
			}
		printf("%s %s\n", service, enable ? "starting" : "stopping");
		system(sprintf("/etc/init.d/%s %s", service, (enable || enable == 'early') ? "restart" : "stop"));
	}
	system("/etc/init.d/dnsmasq restart");
}

try {
	for (let cmd in [ 'rm -rf /tmp/ucentral',
			  'mkdir /tmp/ucentral',
			  'rm /tmp/dnsmasq.conf',
			  '/etc/init.d/spotfilter stop',
			  'touch /tmp/dnsmasq.conf' ])
		system(cmd);

	let state = schemareader.validate(inputjson, logs);

	let batch = state ? renderer.render(state, logs) : "";

	if (state?.strict && length(logs)) {
		push(logs, 'Rejecting config due to strict-mode validation');
		state = null;
	}

	fs.stdout.write("Log messages:\n" + join("\n", logs) + "\n\n");

	if (state) {
		fs.stdout.write("UCI batch output:\n" + batch + "\n");

		let outputjson = fs.open("/tmp/ucentral.uci", "w");
		outputjson.write(batch);
		outputjson.close();

		for (let cmd in [ 'rm -rf /tmp/config-shadow',
				  'rm -rf /tmp/.uci-shadow',
				  'cp -r /etc/config-shadow /tmp',
				  '/usr/share/ucentral/wifi_detect.sh' ])
			system(cmd);

		let apply = fs.popen("/sbin/uci -c /tmp/config-shadow -t /tmp/.uci-shadow batch", "w");
		apply.write(batch);
		apply.close();

		// drop rule files of interfaces that no longer use
		// disallow-upstream-local-subnet; the staged ones are written next
		for (let f in fs.glob('/etc/ucentral/disallow-wan4-*.nft'))
			fs.unlink(f);

		renderer.write_files(logs);

		// refresh the upstream set file before the firewall reload below,
		// so the table-pre include exists when a rule file references it
		if (length(fs.glob('/etc/ucentral/disallow-wan4-*.nft')))
			system('/usr/share/ucentral/wan_subnet.uc');

		set_service_state(false);

		wait_wireless_ready();

		let old_wireguard_peers = wireguard_peers();

		for (let cmd in [ 'uci -c /tmp/config-shadow -t /tmp/.uci-shadow commit',
				  'cp /tmp/config-shadow/* /etc/config/',
				  'rm -rf /tmp/config-shadow',
				  'rm -rf /tmp/.uci-shadow',
				  'sync'])
			system(cmd);

		set_service_state('early');

		ubus.call('state', 'reload');

		for (let cmd in [ 'reload_config',
				  '/etc/init.d/ratelimit reload',
				  '/etc/init.d/dnsmasq restart',
				  '/etc/init.d/ucentral-state restart'])
			system(cmd);

		let new_wireguard_peers = wireguard_peers();
		if (old_wireguard_peers != null && new_wireguard_peers != null &&
		    old_wireguard_peers != new_wireguard_peers) {
			system('ifup wg0');

			let up = false;
			for (let i = 0; i < 15 && !up; i++) {
				sleep(1000);
				up = ubus.call('network.interface.wg0', 'status')?.up;
			}
			if (!up) {
				let msg = 'wireguard: wg0 did not come back up after its peers changed';
				warn(msg + "\n");
				push(logs, msg);
			}
		}

		if (!custom_config) {
			fs.unlink('/etc/ucentral/ucentral.active');
			fs.symlink(ARGV[0], '/etc/ucentral/ucentral.active');
			let cfgs = [];
			for (let k, v in fs.lsdir('/etc/ucentral/'))
				if (wildcard(v, 'ucentral.cfg.1*', true))
					push(cfgs, v);
			cfgs = sort(cfgs);
			while (length(cfgs) >= 5) {
				fs.unlink('/etc/ucentral/' + cfgs[0]);
				shift(cfgs);
			}
		}

		set_service_state(true);
		set_service_state('no-restart');
		ubus.call('mpsk', 'flush');
	} else {
		error = 1;
	}
	if (!length(batch) || !state)
		error = 2;
	else if (length(logs))
		error = 1;
}
catch (e) {
	error = 2;
	warn("Fatal error while generating UCI: ", e, "\n", e.stacktrace[0].context, "\n");
}

if (inputjson.uuid && inputjson.uuid > 1 && !custom_config) {
	let text = [ 'Success', 'Rejects', 'Failed' ];
	let status = {
		error,
		text: text[error] || "Failed",
	};
	if (length(logs))
		status.rejected = logs;

	ubus.call("ucentral", "result", {
		uuid: inputjson.uuid || 0,
		id: +ARGV[1] || 0,
		status,
	});
	if (error > 1)
		exit(1);
}
