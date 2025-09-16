{% if (!natlog.enabled) { return; } %}
{% services.set_enabled("natlog", natlog.enabled) %}

set natlog.@natlog[0].enabled={{ b(natlog.enabled) }}
