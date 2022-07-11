{%
if (!quality_of_service)
	quality_of_service = {};
let egress = ethernet.lookup_by_select_ports(quality_of_service.select_ports);
let enable = length(egress);
services.set_enabled("qosify", enable);
if (!enable)
	return;

function get_speed(dev, speed) {
	if (!speed)
		speed = ethernet.get_speed(dev);
	return speed;
}

function get_proto(proto) {
	if (proto == "any")
		return [ "udp", "tcp" ];
	return [ proto ];
}

function get_range(port) {
	if (port.range_end)
		return sprintf("-%d", port.range_end)
}

let fs = require("fs");
let file = fs.open("/tmp/qosify.conf", "w");
for (let class in quality_of_service.classifier) {
	for (let port in class.ports)
		for (let proto in get_proto(port.protocol))
			file.write(sprintf("%s:%d%s %s%s\n", proto, port.port,
					   port.range_end ? sprintf("-%d", port.range_end) : "",
					   port.reclassify ? "" : "+", class.dscp));
	for (let fqdn in class.dns)
		file.write(sprintf("dns:%s%s %s%s\n",
				   fqdn.suffix_matching ? "*." : "", fqdn.fqdn,
				   fqdn.reclassify ? "" : "+", class.dscp));
}
file.close();
%}

set qosify.@defaults[0].bulk_trigger_pps={{ quality_of_service?.bulk_detection?.packets_per_second || 0}}
set qosify.@defaults[0].dscp_bulk={{ quality_of_service?.bulk_detection?.dscp }}

{% for (let dev in egress): %}
set qosify.{{ dev }}=device
set qosify.{{ dev }}.name={{ s(dev) }}
set qosify.{{ dev }}.bandwidth_up='{{ get_speed(dev, quality_of_service.bandwidth_up) }}mbit'
set qosify.{{ dev }}.bandwidth_down='{{ get_speed(dev, quality_of_service.bandwidth_down) }}mbit'
{% endfor %}
