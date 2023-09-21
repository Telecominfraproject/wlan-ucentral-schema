function log(msg) {
	system('logger RRM: ' + msg );
}

let handlers = {
        // ubus call usteer2 command '{"action": "kick", "addr": "1c:57:dc:37:3c:b1", "reason": 5, "ban_time": 30 }'
	kick: function(params) {
		if (!params.addr)
			return false;
		params.reason ??= 5;
		params.ban_time ??= 30;
		return true;
	},

	// ubus call usteer2 command '{"action": "beacon_request", "addr": "4e:7f:3e:2c:8a:68", "channel": 36 }'
        // ubus call usteer2 command '{"action": "beacon_request", "addr": "4e:7f:3e:2c:8a:68", "ssid": "Cockney" }'
	beacon_request: function(params) {
		if (!params.addr)
			return false;
		return true;
	},

	// ubus call usteer2 command '{"action": "channel_switch", "bssid": "34:eF:b6:aF:48:b1", "params": "channel": 4, "band": "2G"}'
	channel_switch: function(params) {
		if (!params.bssid || !params.channel)
			return false;
		return true;
	},

	// ubus call usteer2 command '{"action": "tx_power", "bssid": "34:eF:b6:aF:48:b1", "level": 20 }'
	tx_power: function(params) {
		if (!params.bssid || !params.level)
			return false;
		return true;
	},

	// ubus call usteer2 command '{"action": "bss_transition", "addr": "4e:7f:3e:2c:8a:68", "params": "neighbors": ["34:ef:b6:af:48:b1"] }'
	bss_transition: function(params) {
		if (!params.addr || !params.neighbors)
			return false;
		for (let neighbor in params.neighbors)
			if (type(neighbor) != 'string')
				return false;
		return true;
	},

	// ubus call usteer2 command '{"action": "neighbors", "neighbors": [ [ "00:11:22:33:44:55", "OpenWifi", "34efb6af48b1af4900005301070603010300" ], [ "aa:bb:cc:dd:ee:ff", "OpenWifi2", "34efb6af48b1af4900005301070603010300" ] ] }'
	neighbors: function(params) {
		if (!params.neighbors)
			return false;
		return true;
	}
};

if (type(args.actions) != 'array')
	return;

for (let action in args.actions) {
	if (type(action) != 'object')
		continue;
	if (!handlers[action.action] || !handlers[action.action](action))
		continue;
	action.event = true;
	let result = ctx.call('rrm', 'command', action);
	log(result);
}
