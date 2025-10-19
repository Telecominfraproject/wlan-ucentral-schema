import * as fs from 'fs';

function sum(arr) {
	let rv = 0;

	for (let val in arr)
		rv += +val;

	return rv;
};

function cpu_stats() {
	let proc = fs.open('/proc/stat', 'r');
	let stats;

	if (proc) {
		let line;

		stats = [];
		while (line = proc.read('line')) {
			let cols = split(replace(trim(line), '  ', ' '), ' ');

			if (!wildcard(cols[0], 'cpu*'))
				continue;

			shift(cols);
			push(stats, [ sum(cols), +cols[3] ]);
		}
		proc.close();
	}
	return stats;
};

function get_cpu_load() {
	let cpu_load = [];
	let last;
	let file = fs.open('/tmp/cpu_load', 'r');
	
	if (file) {
		last = json(file.read('all'));
		file.close();
	}
	
	let now = cpu_stats();
	
	if (now && last)
		for (let i = 0; i < length(now); i++)
			push(cpu_load, 100 - (100 * (now[i][1] - last[i][1]) / (now[i][0] - last[i][0])));
	
	// Save current stats for next iteration
	file = fs.open('/tmp/cpu_load', 'w');
	if (file) {
		file.write(now);
		file.close();
	}
	
	return cpu_load;
};

function get_temperature() {
	let thermal = fs.glob('/sys/class/thermal/thermal_zone*/temp');
	
	if (length(thermal) == 0)
		return null;
	
	let temps = [];
	
	for (let t in thermal) {
		let file = fs.open(t, 'r');

		if (!file)
			continue;
			
		let temp = +file.read('all');

		if (temp > 1000)
			temp /= 1000;
		file.close();
		
		// skip non-connected thermal zones
		if (temp < 200)
			push(temps, temp);
	}
	
	if (length(temps) == 0)
		return null;
	
	temps = sort(temps);

	let avg = 0;

	for (let t in temps)
		avg += t;
	avg /= length(temps);
	
	let max_temp = temps[length(temps) - 1];
	return [ avg, max_temp ];
};

export function collect(state) {
	let sysinfo = global.ubus.call("system", "info");
	
	state.unit = {
		localtime: sysinfo.localtime,
		uptime: sysinfo.uptime,
		load: [ ...sysinfo.load ],
		memory: {
			total: sysinfo.memory.total,
			free: sysinfo.memory.free,
			cached: sysinfo.memory.cached,
			buffered: sysinfo.memory.buffered
		}
	};
	
	// Normalize load values
	for (let l = 0; l < 3; l++)
		state.unit.load[l] /= 65535.0;
	
	// Add CPU load if available
	let cpu_load = get_cpu_load();
	if (length(cpu_load) > 0)
		state.unit.cpu_load = cpu_load;
	
	// Add temperature if available
	let temperature = get_temperature();
	if (temperature)
		state.unit.temperature = temperature;
};
