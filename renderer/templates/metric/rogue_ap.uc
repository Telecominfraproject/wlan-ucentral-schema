{% if (!rogue_ap) return %}

# Rogue AP detection configuration

add rogueap config
set rogueap.@config[-1].interval={{ rogue_ap.interval }}
set rogueap.@config[-1].override_dfs={{ int(rogue_ap.override_dfs) }}

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
