{% if (!services.is_present("sonicfi_poe")) return %}
{% services.set_enabled("sonicfi_poe", true) %}
{%
	let ethernet_poe = {
		lookup: function(globs) {
			let matched = {};

			for (let glob, tag_state in globs){
				for (let name, spec in ethernet.ports){
					if (wildcard(name, glob))
						matched[name] = tag_state;
				}
			}
			return matched;
		},

		lookup_by_select_ports: function(select_ports) {
			let globs = {};
			map(select_ports, glob => globs[glob] = true);

			return sort(keys(this.lookup(globs)));
		}
	};

	for (let ports in poe.ports){
		include("poe/ports.uc", {
			ports: ports,
			ethernet_poe: ethernet_poe
		});
	}
%}
