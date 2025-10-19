
{%
// Helper functions
function has_system_config() {
	return unit.name || unit.hostname || unit.location || unit.timezone;
}

function has_password_config() {
	return unit.system_password || unit.random_password;
}

function configure_password() {
	if (unit.system_password) {
		shell.system_password(unit.system_password);
	} else if (unit.random_password) {
		shell.password(unit.random_password);
	}
}

// Main configuration generation
%}
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
// Configure system password if specified
if (has_password_config()) {
	configure_password();
}

// Enable LED service
services.set_enabled("led", true);
%}
