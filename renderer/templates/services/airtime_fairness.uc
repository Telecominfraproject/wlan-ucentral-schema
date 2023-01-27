{%
let enable = length(airtime_fairness);
services.set_enabled("atfpolicy", enable);
if (!enable)
	return;
%}

set atfpolicy.@defaults[0].vo_queue_weight={{ airtime_fairness.voice_weight }}
set atfpolicy.@defaults[0].update_pkt_threshold={{ airtime_fairness.packet_threshold }}
set atfpolicy.@defaults[0].bulk_percent_thresh={{ airtime_fairness.bulk_threshold }}
set atfpolicy.@defaults[0].prio_percent_thresh={{ airtime_fairness.priority_threshold }}
set atfpolicy.@defaults[0].weight_normal={{ airtime_fairness.weight_normal }}
set atfpolicy.@defaults[0].weight_prio={{ airtime_fairness.weight_priority }}
set atfpolicy.@defaults[0].weight_bulk={{ airtime_fairness.weight_bulk }}

