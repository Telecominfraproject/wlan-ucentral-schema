{%
if (!services.is_present("rrmd"))
	return;
services.set_enabled("rrmd", true);
%}

set rrmd.@base[0].beacon_request_assoc={{ rrm?.beacon_request_assoc || 0 }}
set rrmd.@base[0].station_stats_interval={{ rrm?.station_stats_interval || 0 }}
