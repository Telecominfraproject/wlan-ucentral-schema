export function collect(state) {
	/* Collect data via ubus */
	let captive = global.ubus.call("spotfilter", "client_list", { "interface": "hotspot"});
	
	if (!length(captive))
		return;
		
	let res = {};
	let t = time();

	for (let c, val in captive) {
		res[c] = {
			status: val.state ? 'Authenticated' : 'Garden',
			idle: val.idle || 0,
			time: val.data.connect ? t - val.data.connect : 0,
			ip4addr: val.ip4addr || '',
			ip6addr: val.ip6addr || '',
			packets_ul: val.packets_ul || 0,
			bytes_ul: val.bytes_ul || 0,
			packets_dl: val.packets_dl || 0,
			bytes_dl: val.bytes_dl || 0,
			username: val?.data?.radius?.request?.username || '',
		};
	}
	state.captive = res;
};