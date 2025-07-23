
# Raw Configuration
{% for (let config in config_raw): %}
{% if (config[0] == "add"): %}
{{ config[0] }} {{ config[1] }} {{ config[2] }}
{% else  %}
{{ config[0] }} {{ config[1] }}{{config[2] ? '=' + config[2] : ''}}
{% endif %}
{% endfor %}
