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

if (quality_of_service.services) {
	let inputfile = fs.open('/usr/share/ucentral/qos.json', "r");
	let db = json(inputfile.read("all"));

	for (let k, v in db.classes) {
%}
set qosify.{{ k }}=class
set qosify.{{ k }}.ingress={{ s(v.ingress) }}
set qosify.{{ k }}.egress={{ s(v.egress) }}
set qosify.{{ k }}.bulk_trigger_pps={{ s(v.bulk_pps) }}
set qosify.{{ k }}.bulk_trigger_timeout={{ s(v.bulk_timeout) }}
set qosify.{{ k }}.dscp_bulk={{ s(v.bulk_dscp) }}
{%
	}

	let rules = [];
	let all = 'all' in quality_of_service.services;
	for (let k, v in db.services)
		if (all || (k in quality_of_service.services))
			for (let uses in v.uses)
				push(quality_of_service.services, uses);
	for (let k, v in db.services)
		if (all || (k in quality_of_service.services)) {
			for (let port in v.tcp)
				push(rules, 'tcp:' + port + ' ' + v.classifier);
			for (let port in v.udp)
				push(rules, 'udp:' + port + ' ' + v.classifier);
			for (let dns in v.fqdn)
				push(rules, 'dns:' + dns + ' ' + v.classifier);
		}

	for (let rule in uniq(rules))
		file.write(rule + '\n');
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
