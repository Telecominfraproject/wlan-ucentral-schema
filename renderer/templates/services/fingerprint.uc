{%
if (!services.is_present("ufp"))
	return;
services.set_enabled("ufp", state.services?.fingerprint);
if (!state.services?.fingerprint)
	return;
%}
set state.fingerprint=fingerprint
set state.fingerprint.mode={{ s(state.services.fingerprint.mode) }}
set state.fingerprint.min_age={{ s(state.services.fingerprint.minimum_age) }}
set state.fingerprint.max_age={{ s(state.services.fingerprint.maximum_age) }}
set state.fingerprint.period={{ s(state.services.fingerprint.periodicity) }}
set state.fingerprint.allow_wan={{ b(state.services.fingerprint.allow_wan) }}
