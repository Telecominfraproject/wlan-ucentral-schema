{%
if (!services.is_present("rrmd"))
	return;
services.set_enabled("rrmd", true);

function sec_to_ms(sec) {
	let ms = sec*1000;
	return ms;
}

function algo_to_num(algo_name) {
	switch(algo_name){
		case 'rcs':
			res = 1;
			break;
		case 'acs':
			res = 2;
			break;
		default:
			res = 0;
			break;
	}

	return res;
}
%}

set rrmd.@base[0].beacon_request_assoc={{ b(rrm?.beacon_request_assoc || false) }}
set rrmd.@base[0].station_stats_interval={{ rrm?.station_stats_interval || 0 }}

# RRM policy configuration for Optimization based on Channel Utilization
{% if (rrm?.chanutil): %}
	add rrmd policy
	set rrmd.@policy[-1].name='chanutil'
	set rrmd.@policy[-1].interval={{ sec_to_ms(rrm?.chanutil.interval || 240) }}
	set rrmd.@policy[-1].threshold={{ rrm?.chanutil.threshold || 0 }}
	set rrmd.@policy[-1].consecutive_threshold_breach={{ rrm?.chanutil.consecutive_threshold_breach || 1 }}
	set rrmd.@policy[-1].algo={{ algo_to_num(rrm?.chanutil.algo || 1) }}
{% endif %}
