export function collect(state) {
	/* Collect data via ubus */
	let ieee8021x = global.ubus.call("ieee8021x", "dump");
	
	if (!ieee8021x)
		return;
		
	state.ieee8021x = ieee8021x;
};