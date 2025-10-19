export function collect(state) {
	/* Collect data via ubus */
	let gps = global.ubus.call("gps", "info");
	
	if (!length(gps) || !gps.latitude)
		return;
		
	state.gps = {
		latitude: gps.latitude,
		longitude: gps.longitude,
		elevation: gps.elevation
	};
};