{% if (!services.is_present("natlog")) return; %}
{% services.set_enabled("natlog", natlog.enabled); %}

add natlog defaults
set natlog.@defaults[0].enabled={{ b(natlog.enabled) }}
