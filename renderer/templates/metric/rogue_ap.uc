{%
	if (!services.is_present("rogueap"))
		return;

	let enable = !!rogue_ap?.interval;

	services.set_enabled("rogueap", enable ? "no-restart" : false);

	if (!enable)
		return;
%}

# Rogue AP detection configuration

add rogueap config
set rogueap.@config[-1].interval={{ int(rogue_ap.interval) }}
set rogueap.@config[-1].override_dfs={{ int(rogue_ap.override_dfs ?? false) }}

{% if (length(rogue_ap.administeredbssid || []) > 0): %}
add rogueap administeredbssid
{%   for (let bssid in rogue_ap.administeredbssid): %}
add_list rogueap.@administeredbssid[-1].bssid={{ s(bssid) }}
{%   endfor %}
{% endif %}

{% for (let idx, rules in rogue_ap.rules): %}
add rogueap rules
{%   if (exists(rules, "ssid")): %}
set rogueap.@rules[-1].ssid={{ s(rules.ssid) }}
{%   endif %}
{%   if (exists(rules, "bssid")): %}
set rogueap.@rules[-1].bssid={{ s(rules.bssid) }}
{%   endif %}
{%   if (exists(rules, "rssi")): %}
set rogueap.@rules[-1].rssi={{ int(rules.rssi) }}
{%   endif %}
{%   if (exists(rules, "vendor")): %}
set rogueap.@rules[-1].vendor={{ s(rules.vendor) }}
{%   endif %}
{% endfor %}
