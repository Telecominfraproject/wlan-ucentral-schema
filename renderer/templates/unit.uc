
# Basic unit configuration
{% if (unit.name): %}
set system.@system[-1].description={{ s(unit.name) }}
{% endif %}
{% if (unit.hostname): %}
set system.@system[-1].hostname={{ s(unit.hostname) }}
{% endif %}
{% if (unit.location): %}
set system.@system[-1].notes={{ s(unit.location) }}
{% endif %}
{% if (unit.timezone): %}
set system.@system[-1].timezone={{ s(unit.timezone) }}
{% endif %}
set system.@system[-1].leds_off={{ b(!unit.leds_active) }}
{%
if (unit.system_password)
	shell.system_password(unit.system_password);
else
	shell.password(unit.random_password);
services.set_enabled("led", true);
%}
