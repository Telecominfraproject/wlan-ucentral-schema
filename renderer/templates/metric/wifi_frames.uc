{% if (!wifi_frames) return %}

# Wifi-frame reporting configuration
set event.wifi=event
set event.wifi.type=wifi
{% if (!wifi_frames.filters || length(wifi_frames.filters) == 0): %}
set event.wifi.filter='*'
{% else %}
{% for (let n, filter in wifi_frames.filters): %}
{{ n ? 'add_list' : 'set' }} event.wifi.filter={{ filter }}
{% endfor %}
{% endif %}
