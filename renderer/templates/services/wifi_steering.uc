{% if (!services.is_present("usteer")) return %}
{% let ssids = services.lookup_ssids("wifi-steering") %}
{% let enable = length(ssids) %}
{% services.set_enabled("usteer", enable) %}
{% if (!enable) return %}
{% let name = wifi_steering.mode == 'local' ? ethernet.find_interface("upstream", 0) : '' %}
# Wifi-Steering service configuration

add usteer usteer
set usteer.@usteer[-1].network={{ s(name) }}
set usteer.@usteer[-1].ipv6={{ b(wifi_steering.ipv6) }}
set usteer.@usteer[-1].key={{ s(wifi_steering.key) }}
set usteer.@usteer[-1].assoc_steering={{ b(wifi_steering.assoc_steering) }}
set usteer.@usteer[-1].min_snr={{ wifi_steering.required_snr }}
set usteer.@usteer[-1].min_connect_snr={{ wifi_steering.required_probe_snr }}
set usteer.@usteer[-1].roam_scan_snr={{ wifi_steering.required_roam_snr }}
set usteer.@usteer[-1].load_kick_enabled={{ b(wifi_steering.load_kick_threshold) }}
set usteer.@usteer[-1].load_kick_threshold={{ wifi_steering.load_kick_threshold }}
set usteer.@usteer[-1].autochannel={{ b(wifi_steering.auto_channel) }}
{% for (let ssid in ssids): %}
add_list usteer.@usteer[-1].ssid_list={{ s(ssid.name) }}
{% endfor %}

add firewall rule
set firewall.@rule[-1].name='Allow-usteer-{{ name }}'
set firewall.@rule[-1].src='{{ name }}'
set firewall.@rule[-1].dest_port='16720'
set firewall.@rule[-1].proto='udp'
set firewall.@rule[-1].target='ACCEPT'
