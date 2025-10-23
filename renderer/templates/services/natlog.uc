{% if (!natlog.enabled) return; %}
{% services.set_enabled("natlog", true); %}

set natlog.@defaults[0].enabled={{ b(natlog.enabled) }}
