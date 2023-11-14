{% if (state.switch.port_mirror && state.switch.port_mirror.monitor_ports && state.switch.port_mirror.analysis_port): %}

{%
    let analysis = ethernet.lookup_by_select_ports([state.switch.port_mirror.analysis_port]);
    ethernet.reserve_port(state.switch.port_mirror.analysis_port);
    let mirrors = ethernet.lookup_by_select_ports(state.switch.port_mirror.monitor_ports);
%}

# Switch  port-mirror configuration

set switch.mirror=port-mirror
{%   for (let mirror in mirrors): %}
add_list switch.mirror.monitor={{ s(mirror) }}
{%   endfor %}
set switch.mirror.analysis={{ s(analysis[0]) }}

{% endif %}

set network.mirror=interface
set network.mirror.ifname=eth1
set network.mirror.proto=none
