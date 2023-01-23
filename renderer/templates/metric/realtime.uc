{% if (!realtime) return %}

# Realtime event configuration
{% for (let real in realtime.types): %}
{%   if (!(real in events)) continue; %}
add_list event.realtime.filter={{ real }}
{% endfor %}
