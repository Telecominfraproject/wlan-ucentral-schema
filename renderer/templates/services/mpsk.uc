{%
services.set_enabled("mpskd", services.lookup_ssids_by_mpsk() ? 'no-restart' : false);
%}
