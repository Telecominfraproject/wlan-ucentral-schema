// Ethernet utility library for uCentral schema renderer
// Extracted from renderer.uc to enable code sharing between renderer and tests

"use strict";

/**
 * @class uCentral.ethernet
 * @classdesc
 *
 * This is the ethernet base class. It is automatically instantiated and
 * accessible using the global 'ethernet' variable.
 */

/** @lends uCentral.ethernet.prototype */

function create_ethernet(ports, capab, fs, swconfig) {
	return {
		ports: ports,
		swconfig: swconfig,
		
		reverse_lookup: function(iface) {
			for (let name, dev in this.ports)
				if (dev == iface)
					return name;
			return null;
		},

		lookup_port: function(iface) {
			for (let name, dev in this.ports)
				if (dev.netdev == iface)
					return dev;
			return null;
		},

		/**
		 * Get a list of all wireless PHYs for a specific wireless band
		 *
		 * @param {string} band
		 *
		 * @returns {object}
		 * Returns an array of all wireless PHYs for a specific wireless
		 * band.
		 */
		lookup: function(globs) {
			let matched = {};

			for (let glob, tag_state in globs) {
				for (let name, spec in this.ports) {
					if (wildcard(name, glob)) {
						if (spec.netdev)
							matched[spec.netdev] = tag_state;
						else
							warn("Not implemented yet: mapping switch port to netdev");
					}
				}
			}

			return matched;
		},

		lookup_name: function(globs) {
			let matched = {};

			for (let glob, tag_state in globs){
				for (let name, spec in this.ports){
					if (wildcard(name, glob))
						matched[name] = tag_state;
				}
			}
			return matched;
		},

		lookup_by_interface_vlan: function(interface, raw) {
			// Gather the glob patterns in all `ethernet: [ { select-ports: ... }]` specs,
			// dedup them and turn them into one global regular expression pattern, then
			// match this pattern against all known system ethernet ports, remember the
			// related netdevs and return them.
			let globs = {};
			map(interface.ethernet, eth => map(eth.select_ports, glob => globs[glob] = eth.vlan_tag));

			let lookup = this.lookup(globs);
			if (raw)
				return lookup;

			let rv = {};
			for (let k, v in lookup) {
				/* tagged swconfig downstream ports are not allowed */
				if (interface.role == 'downstream') {
					if (this.swconfig && this.swconfig[k].switch && v == 'tagged')
						warn('%s:%d - vlan tagging on downstream swconfig ports is not supported', this.swconfig[k]?.switch.name, this.swconfig[k].swconfig);
					else
						rv[k] = v;
					continue;
				}
				/* resolve upstream vlans on swconfig ports */
				if (this.swconfig && interface.role == 'upstream' && interface.vlan.id && this.swconfig[k]?.switch) {
					rv[split(k, '.')[0] + '.' + interface.vlan.id] = 'un-tagged';
					continue;
				}
				rv[k] = v;
			}
			return rv;
		},

		switch_by_interface_vlan: function(interface, raw) {
			let ports = this.lookup_by_interface_vlan(interface, true);
			let rv = { ports: "" };
			let cpu_port = 0;
			for (let port, tag in ports) {
				if (!this.swconfig || !this.swconfig[port]?.switch) continue;
				rv.name = this.swconfig[port].switch.name;
				cpu_port = this.swconfig[port].switch.port;
				rv.ports += ' ' + this.swconfig[port].swconfig;
				if (tag != 'un-tagged')
					rv.ports += 't';
			}
			if (!rv.name)
				return null;
			rv.ports = cpu_port + 't' + rv.ports;

			return rv;
		},

		lookup_by_interface_spec: function(interface) {
			return sort(keys(this.lookup_by_interface_vlan(interface)));
		},

		lookup_by_select_ports: function(select_ports) {
			let globs = {};
			map(select_ports, glob => globs[glob] = true);

			return sort(keys(this.lookup(globs)));
		},

		lookup_name_by_select_ports: function(select_ports) {
			let globs = {};
			map(select_ports, glob => globs[glob] = true);

			return sort(keys(this.lookup_name(globs)));
		},

		lookup_by_ethernet: function(ethernets) {
			let result = [];

			for (let ethernet in ethernets)
				result = [ ...result,  ...this.lookup_by_select_ports(ethernet.select_ports) ];
			return result;
		},

		reserve_port: function(port) {
			delete this.ports[port];
		},

		is_single_config: function(interface) {
			let ipv4_mode = interface.ipv4 ? interface.ipv4.addressing : 'none';
			let ipv6_mode = interface.ipv6 ? interface.ipv6.addressing : 'none';

			return (
				(ipv4_mode == 'none') || (ipv6_mode == 'none') ||
				(ipv4_mode == 'static' && ipv6_mode == 'static')
			);
		},

		calculate_name: function(interface) {
			let vid = interface.vlan.id;
			if (interface.admin_ui)
				return 'admin_ui';
			return (interface.role == 'upstream' ? 'up' : 'down') + interface.index + 'v' + vid;
		},

		calculate_names: function(interface) {
			let name = this.calculate_name(interface);

			return this.is_single_config(interface) ? [ name ] : [ name + '_4', name + '_6' ];
		},

		calculate_ipv4_name: function(interface) {
			let name = this.calculate_name(interface);

			return this.is_single_config(interface) ? name : name + '_4';
		},

		calculate_ipv6_name: function(interface) {
			let name = this.calculate_name(interface);

			return this.is_single_config(interface) ? name : name + '_6';
		},

		has_vlan: function(interface) {
			return interface.vlan && interface.vlan.id;
		},

		port_vlan: function(interface, port) {
			if (port == "tagged")
				return ':t';
			if (port == "un-tagged")
				return '';
			return ((interface.role == 'upstream') && this.has_vlan(interface)) ? ':t' : '';
		},

		find_interface: function(role, vid) {
			for (let interface in state.interfaces)
				if (interface.role == role &&
				    interface.vlan?.id == vid)
					return this.calculate_name(interface);
			return '';
		},

		get_interface: function(role, vid) {
			for (let interface in state.interfaces)
				if (interface.role == role &&
				    interface.vlan.id == vid)
					return interface;
			return null;
		},

		get_speed: function(dev) {
			let fp = fs.open(sprintf("/sys/class/net/%s/speed", dev));
			if (!fp)
				return 1000;
			let speed = fp.read("all");
			fp.close();
			return +speed;
		}
	};
}

export { create_ethernet };
