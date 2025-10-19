export function collect(state) {
	/* Collect data via ubus */
	let poe = global.ubus.call("poe", "info");
	
	if (!length(poe))
		return;
		
	state.poe = {};
	state.poe.consumption = poe.consumption;
	state.poe.ports = [];
	for (let k, v in poe.ports) {
		let port = {
			id: replace(k, 'lan', ''),
			status: v.status
		};
		if (v.consumption)
			port.consumption = v.consumption;
		push(state.poe.ports, port);
	}
};