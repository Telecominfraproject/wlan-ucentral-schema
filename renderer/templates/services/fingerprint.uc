{% if (!services.is_present("ufp")) return %}
{% services.set_enabled("ufp", state.services?.fingerprint) %}

