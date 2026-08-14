/* spotfilter interfaces are named after the uspot config sections that the
 * renderer emits (e.g. "down2v0_0"), so query each one instead of assuming a
 * fixed "hotspot" instance. */
function captive_clients() {
	let res = {};

	for (let section, config in global.uci.get_all("uspot") ?? {}) {
		if (config?.[".type"] != "uspot")
			continue;
		let clients = global.ubus.call("spotfilter", "client_list", { interface: section });
		for (let mac, val in clients)
			res[mac] = val;
	}

	return res;
}

export function collect(state) {
	/* Collect data via ubus */
	let captive = captive_clients();

	if (!length(captive))
		return;

	let res = {};
	let t = time();

	for (let c, val in captive) {
		res[c] = {
			status: val.state ? 'Authenticated' : 'Garden',
			idle: val.idle || 0,
			time: val?.data?.connect ? t - val.data.connect : 0,
			ip4addr: val.ip4addr || '',
			ip6addr: val.ip6addr || '',
			/* spotfilter reports the per client counters nested in acct_data */
			packets_ul: val?.acct_data?.packets_ul || 0,
			bytes_ul: val?.acct_data?.bytes_ul || 0,
			packets_dl: val?.acct_data?.packets_dl || 0,
			bytes_dl: val?.acct_data?.bytes_dl || 0,
			username: val?.data?.radius?.request?.username || '',
		};
	}
	state.captive = res;
};