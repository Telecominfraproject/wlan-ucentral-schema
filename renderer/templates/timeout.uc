
# Basic unit configuration
{% for (let t in [ 'offline', 'orphan', 'validate' ]):
	if (timeout[t]):
%}
set ucentral.timeouts.{{ t }}={{ timeout[t] }}
{%	endif
   endfor %}
