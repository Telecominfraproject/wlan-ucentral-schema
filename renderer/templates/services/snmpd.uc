{%

if (!length(snmpd)) return;
let interfaces = services.lookup_interfaces("snmpd");
%}


# SNMPD service configuration
set snmpd.general.enabled={{ s(snmpd.general.enabled) }} 
{% for (let interface in interfaces): %}                                                                                                                                                                           
{%    let name = ethernet.calculate_name(interface) %} 
add_list snmpd.general.network={{ name }}
{% endfor %}


add agent
set snmpd.@agent[-1].agentaddress={{ s(snmpd.agent.agentaddress) }}

add system
set snmpd.@system[-1].sysLocation={{ s(snmpd.system.sysLocation) }}
set snmpd.@system[-1].sysContact={{ s(snmpd.system.sysContact) }}
set snmpd.@system[-1].sysName={{ s(snmpd.system.sysName) }}

add agentx
set snmpd.@agentx[-1].type={{ s(snmpd.agentx.type) }}

{% for (let g, v in snmpd.group): %}
set snmpd.{{g}}.group={{ s(v.group) }}
set snmpd.{{g}}.version={{ s(v.version) }}
set snmpd.{{g}}.secname={{ s(v.secname) }}
{% endfor %}

{% for (let n, v in snmpd.view): %}
set snmpd.{{n}}.viewname={{ s(v.viewname) }}
set snmpd.{{n}}.type={{ s(v.type) }}
set snmpd.{{n}}.oid={{ s(v.oid) }}
{% endfor %}

{% for (let c, v in snmpd.com2sec): %}
set snmpd.{{c}}.secname={{ s(v.secname) }}
set snmpd.{{c}}.source={{ s(v.source) }}
set snmpd.{{c}}.community={{ s(v.community) }}
{% endfor %}

{% for (let p, v in snmpd.pass): %}
add snmpd pass
set snmpd.@pass[-1].name={{ s(v.name) }}
set snmpd.@pass[-1].miboid={{ s(v.miboid) }}
set snmpd.@pass[-1].prog={{ s(v.prog) }}
{% endfor %}

{% for (let a, v in snmpd.access): %}
add access
set snmpd.{{a}}.context={{ s(v.context) }}
set snmpd.{{a}}.version={{ s(v.version) }}
set snmpd.{{a}}.level={{ s(v.level) }}
set snmpd.{{a}}.prefix={{ s(v.prefix) }}
set snmpd.{{a}}.read={{ s(v.read) }}
set snmpd.{{a}}.write={{ s(v.write) }}
set snmpd.{{a}}.notify={{ s(v.notify) }}
set snmpd.{{a}}.group={{ s(v.group) }}
{% endfor %}

{% let port = split(snmpd.agent.agentaddress, ':')[1] %}
{% for (let interface in interfaces): %}                                                                                                                                                                           
{%    let name = ethernet.calculate_name(interface) %} 
add firewall rule
set firewall.@rule[-1].name='Allow SNMP'
set firewall.@rule[-1].src={{ name }}
set firewall.@rule[-1].dest_port={{port}}
set firewall.@rule[-1].proto='udp'
set firewall.@rule[-1].target='ACCEPT' 
