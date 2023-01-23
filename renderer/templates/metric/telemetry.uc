{% if (!telemetry) return %}

# Telemetry streaming configuration
set event.bulk.interval={{ telemetry.interval }}
{% for (let type in telemetry.types): %}
{%   if (!(type in events)) continue; %}
add_list event.bulk.filter={{ type }}
{% endfor %}
