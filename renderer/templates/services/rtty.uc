{% if (!services.is_present("rtty")) return %}
{% let enable = length(rtty) %}
{% services.set_enabled("rtty", enable) %}
{% if (!enable) return %}

# RTTY service configuration

set rtty.@rtty[-1].enable={{ b((rtty.token && rtty.host && rtty.port)) }}
set rtty.@rtty[-1].token={{ s(rtty.token) }}
set rtty.@rtty[-1].host={{ s(rtty.host) }}
set rtty.@rtty[-1].port={{ s(rtty.port) }}
set rtty.@rtty[-1].ssl={{ b(rtty.mutual_tls) }}
