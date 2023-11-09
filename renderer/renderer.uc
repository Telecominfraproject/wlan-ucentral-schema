// UCI batch output master template

"use strict";

let uci = require("uci");
let ubus = require("ubus");
let fs = require("fs");

let cursor = uci ? uci.cursor() : null;
let conn = ubus ? ubus.connect() : null;

let capabfile = fs.open("/etc/ucentral/capabilities.json", "r");
let capab = capabfile ? json(capabfile.read("all")) : null;

let pipe = fs.popen('fw_printenv developer');
let developer = replace(pipe.read("all"), '\n', '');
pipe.close();
let restrict = {};
if (developer != 'developer=1') {
	let restrictfile = fs.open("/etc/ucentral/restrictions.json", "r");
	restrict = restrictfile ? json(restrictfile.read("all")) : {};
}

let serial = cursor.get("ucentral", "config", "serial");

assert(cursor, "Unable to instantiate uci");
assert(conn, "Unable to connect to ubus");
assert(capab, "Unable to load capabilities");

let topdir = sourcepath(0, true);

/**
 * Formats a given input value as uci boolean value.
 *
 * @memberof uCentral.prototype
 * @param {*} val The value to format
 * @returns {string}
 * Returns '1' if the given value is truish (not `false`, `null`, `0`,
 * `0.0` or an empty string), or `0` in all other cases.
 */
function b(val) {
	return val ? '1' : '0';
}

/**
 * Formats a given input value as single quoted string, honouring uci
 * specific escaping semantics.
 *
 * @memberof uCentral.prototype
 * @param {*} str The string to format
 * @returns {string}
 * Returns an empty string if the given input value is `null` or an
 * empty string. Returns the escaped and quoted string in all other
 * cases.
 */
function s(str) {
	if (str === null || str === '')
		return '';

	return sprintf("'%s'", replace(str, /'/g, "'\\''"));
}

/**
 * Attempt to include a file, catching potential exceptions.
 *
 * Try to include the given file path in a safe manner. The
 * path is resolved relative to the path of the currently
 * executed template and may only contain the character `A-Z`,
 * `a-z`, `0-9`, `_`, `/` and `-` as must contain a final
 * `.uc` file extension.
 *
 * Exception occuring while including the file are catched
 * and a warning is emitted instead.
 *
 * @memberof uCentral.prototype
 * @param {string} path Path of the file to include
 * @param {object} scope The scope to pass to the include file
 */
function tryinclude(path, scope) {
	if (!match(path, /^[A-Za-z0-9_\/-]+\.uc$/)) {
		warn("Refusing to handle invalid include path '%s'", path);
		return;
	}

	let parent_path = sourcepath(1, true);

	assert(parent_path, "Unable to determine calling template path");

	try {
		include(parent_path + "/" + path, scope);
	}
	catch (e) {
		warn("Unable to include path '%s': %s\n%s", path, e, e.stacktrace[0].context);
	}
}

function discover_ports() {
	let roles = {};

	/* Derive ethernet port names and roles from default config */
	for (let role, spec in capab.network) {
		for (let i, ifname in spec) {
			role = uc(role);
			let netdev = split(ifname, ':');
			let port = {
				netdev: netdev[0],
				index: i
			};
			if (netdev[1]) {
				port.swconfig = netdev[1];
				port.swdev = split(ifname, ':')[0];
			}
			push(roles[role] = roles[role] || [], port);
		}
	}

	/* Sort ports in each role group according to their index, then normalize
	 * names into uppercase role name with 1-based index suffix in case of multiple
	 * ports or just uppercase role name in case of single ports */
	let rv = {};

	for (let role, ports in roles) {
		switch (length(ports)) {
		case 0:
			break;

		case 1:
			rv[role] = ports[0];
			break;

		default:
			map(sort(ports, (a, b) => (a.index - b.index)), (port, i) => {
				rv[role + (i + 1)] = port;
			});
		}
	}

	return rv;
}

/**
 * @class uCentral.wiphy
 * @classdesc
 *
 * This is the wireless PHY base class. It is automatically instantiated and accessible
  * using the global 'wiphy' variable.
 */

/** @lends uCentral.wiphy.prototype */

let wiphy = {
	/**
	 * Return a list of PHY information structures
	 *
	 * This function returns a list of all available PHYs including
	 * the relevant data describing their properties and capabilities
	 * such as HT Modes, channels, ...
	 *
	 * @method
	 *
	 * @returns {Array}
	 * Returns an array of all available PHYs.
	 */
	phys: require("wifi.phy"),

	/** @private */
	band_freqs: {
		'2G':       [  2412,  2484 ],
		'5G':       [  5160,  5885 ],
		'5G-lower': [  5160,  5340 ],
		'5G-upper': [  5480,  5885 ],
		'6G':       [  5925,  7125 ],
		'60G':		[ 58320, 69120 ]
	},

	/** @private */
	band_channels: {
		'2G': [ 1, 14 ],
		'5G': [ 7, 196 ],
		'5G-lower': [ 7, 68 ],
		'5G-upper': [ 96, 177 ],
		'6G': [ 200, 600 ], // FIXME
		'60G': [ 1, 6 ]
	},

	/**
	 * Convert a wireless channel to a wireless frequency
	 *
	 * @param {string} wireless band
	 * @param {number} channel
	 *
	 * @returns {?number}
	 * Returns the coverted wireless frequency for this specific
	 * channel.
	 */
	channel_to_freq: function(band, channel) {
		if (band == '2G' && channel >= 1 && channel <= 13)
			return 2407 + channel * 5;
		else if (band == '2G' && channel == 14)
			return 2484;
		else if (band == '5G' && channel >= 7 && channel <= 177)
			return 5000 + channel * 5;
		else if (band == '5G' && channel >= 183 && channel <= 196)
			return 4000 + channel * 5;
		else if (band == '60G' && channel >= 1 && channel <= 6)
			return 56160 + channel * 2160;

		return null;
	},

	/**
	 * Convert the unique sysfs path describing a wireless PHY to
	 * the corresponding UCI section name
	 *
	 * @param {string} path
	 *
	 * @returns {string|false}
	 * Returns the UCI section name of a specific PHY
	 */
	path_to_section: function(path) {
		let sid = null;

		cursor.load("wireless");
		cursor.foreach("wireless", "wifi-device", (s) => {
			if (s.path == path && s.scanning != 1) {
				sid = s['.name'];

				return false;
			}
		});

		return sid;
	},

	/**
	 * Get a list of all wireless PHYs for a specific wireless band
	 *
	 * @param {string} band
	 *
	 * @returns {object[]}
	 * Returns an array of all wireless PHYs for a specific wireless
	 * band.
	 */
	lookup_by_band: function(band) {
		let baseband = band;
		let phys = [];

		if (band in ['5G-lower', '5G-upper'])
			baseband = '5G';

		for (let path, phy in this.phys) {
			if (!(baseband in phy.band))
				continue;

			let phy_min_freq, phy_max_freq;

			if (phy.frequencies) {
				phy_min_freq = min(...phy.frequencies);
				phy_max_freq = max(...phy.frequencies);
			}
			else {
				/* NB: this code is superfluous once ubus call wifi phy reports
				       supported frequencies directly */

				let min_ch = max(min(...phy.channels), this.band_channels[band][0]),
				    max_ch = min(max(...phy.channels), this.band_channels[band][1]);

				phy_min_freq = this.channel_to_freq(baseband, min_ch);
				phy_max_freq = this.channel_to_freq(baseband, max_ch);

				if (phy_min_freq === null) {
					warn("Unable to map channel %d in band %s to frequency", min_ch, baseband);
					continue;
				}

				if (phy_max_freq === null) {
					warn("Unable to map channel %d in band %s to frequency", max_ch, baseband);
					continue;
				}
			}

			/* phy's frequency range does not overlap with band's frequency range, skip phy */
			if (phy_max_freq < this.band_freqs[band][0] || phy_min_freq > this.band_freqs[band][1])
				continue;

			let sid = this.path_to_section(path);

			if (sid)
				push(phys, { ...phy, section: sid });
		}

		return phys;
	},

	allocate_ssid_section_id: function(phy) {
		phy.networks = ++phy.networks || 1;

		assert(phy.section, "Radio has no related uci section");

		return phy.section + 'net' + phy.networks;
	}
};

/**
 * @class uCentral.ethernet
 * @classdesc
 *
 * This is the ethernet base class. It is automatically instantiated and
 * accessible using the global 'ethernet' variable.
 */

/** @lends uCentral.ethernet.prototype */

let ethernet = {
	ports: discover_ports(),

	reverse_lookup: function(iface) {
		for (let name, dev in this.ports)
			if (dev == iface)
				return name;
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
			if (this.swconfig && interface.role == 'upstream' && interface.vlan.id && this.swconfig[k]?.switch && v != 'un-tagged') {
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

/**
 * @class uCentral.ipcalc
 * @classdesc
 *
 * The ipcalc utility class provides methods for manipulating and testing
 * IP address ranges.
 */

/** @lends uCentral.ipcalc.prototype */

let ipcalc = {
	used_prefixes: [],

	/**
	 * Convert the given amount of prefix bits to a network mask in IP address
	 * notation.
	 *
	 * @param {number} bits  The amounts of prefix bits
	 * @param {?boolean} v6  If true, produce an IPv6 mask, otherwise use IPv4
	 *
	 * @returns {string}
	 * Returns a string containing the corresponding netmask.
	 *
	 * @throws
	 * Throws an exception when the amount of bits is not representable as netmask.
	 */
	convert_bits_to_mask: function(bits, v6) {
		let width = v6 ? 128 : 32,
		    mask = [];

		assert(bits <= width, "Invalid bit length");

		bits = width - bits;

		for (let i = width / 8; i > 0; i--) {
			let b = (bits < 8) ? bits : 8;
			mask[i - 1] = ~((1 << b) - 1) & 0xff;
			bits -= b;
		}

		return mask;
	},

	apply_mask: function(addr, mask) {
		assert(length(addr) == length(mask), "Incompatible mask");

		return map(addr, (byte, i) => byte & mask[i]);
	},

	is_intersecting_prefix: function(addr1, bits1, addr2, bits2) {
		assert(length(addr1) == length(addr2), "Incompatible addresses");

		let mask = this.convert_bits_to_mask((bits1 < bits2) ? bits1 : bits2, length(addr1) == 16);

		for (let i = 0; i < length(addr1); i++)
			if ((addr1[i] & mask[i]) != (addr2[i] & mask[i]))
				return false;

		return true;
	},

	add_amount: function(addr, amount) {
		for (let i = length(addr); i > 0; i--) {
			let t = addr[i - 1] + amount;
			addr[i - 1] = t & 0xff;
			amount = t >> 8;
		}

		return addr;
	},

	reserve_prefix: function(addr, mask) {
		for (let i = 0; i < length(this.used_prefixes); i += 2) {
			let addr2 = this.used_prefixes[i + 0],
			    mask2 = this.used_prefixes[i + 1];

			if (length(addr2) != length(addr))
				continue;

			if (this.is_intersecting_prefix(addr, mask, addr2, mask2))
				return false;
		}

		push(this.used_prefixes, addr, mask);

		return true;
	},

	generate_prefix: function(state, template, ipv6) {
		let prefix = match(template, /^(auto|[0-9a-fA-F:.]+)\/([0-9]+)$/);

		if (prefix && prefix[1] == 'auto') {
			assert(state.globals && state.globals[ipv6 ? 'ipv6_network' : 'ipv4_network'],
				"No global prefix pool configured");

			let pool = match(state.globals[ipv6 ? 'ipv6_network' : 'ipv4_network'], /^([0-9a-fA-F:.]+)\/([0-9]+)$/);

			assert(prefix[2] >= pool[2],
				"Interface " + (ipv6 ? "IPv6" : "IPv4") + " prefix size exceeds available allocation pool size");

			let available_prefixes = 1 << (prefix[2] - pool[2]),
			    prefix_mask = this.convert_bits_to_mask(prefix[2], ipv6),
			    address_base = iptoarr(pool[1]);

			for (let offset = 0; offset < available_prefixes; offset++) {
				if (this.reserve_prefix(address_base, prefix[2])) {
					this.add_amount(address_base, 1);

					return arrtoip(address_base) + '/' + prefix[2];
				}

				for (let i = length(address_base), carry = 1; i > 0; i--) {
					let t = address_base[i - 1] + (~prefix_mask[i - 1] & 0xff) + carry;
					address_base[i - 1] = t & 0xff;
					carry = t >> 8;
				}
			}

			die("No prefix of size /" + prefix[2] + " available");
		}

		return template;
	},

	expand_wildcard_address: function(wcaddr, prefix) {
		let addr = iptoarr(wcaddr),
		    cidr = match(prefix, /^([0-9a-fA-F:.]+)\/([0-9]+)$/);

		assert(addr, "Invalid wildcard address '" + wcaddr + '"');
		assert(cidr, "Invalid prefix range '" + prefix + '"');

		let mask = this.convert_bits_to_mask(+cidr[2], length(addr) == 16),
		    base = this.apply_mask(iptoarr(cidr[1]), mask),
		    result = [];

		for (let i, b in addr) {
			if (b & mask[i]) {
				warn("Wildcard address '" + wcaddr + "' is partially masked by interface subnet mask '" + arrtoip(mask) + '"');
				break;
			}
		}

		for (let i, b in addr)
			result[i] = base[i] | (b & ~mask[i]);

		return arrtoip(result);
	}
};

/**
 * @class uCentral.services
 * @classdesc
 *
 * The services utility class provides methods for managing and querying
 * service states.
 */

/** @lends uCentral.services.prototype */

let services = {
	state: {},

	set_enabled: function(name, state) {
		if (!this.state[name]) {
			if (state == 'early')
				this.state[name] = 'early';
			else
				this.state[name] = state ? true : false;
		}
	},

	is_present: function(name) {
		return length(fs.stat("/etc/init.d/" + name)) > 0;
	},

	lookup_interfaces: function(service) {
		let interfaces = [];

		for (let interface in state.interfaces) {
			if (!interface.services || index(interface.services, service) < 0)
				continue;
			push(interfaces, interface);
		}

		return interfaces;
	},

	lookup_interfaces_by_ssids: function(service) {
		let interfaces = [];

		for (let interface in state.interfaces) {
			if (!interface.ssids)
				continue;
			for (let ssid in interface.ssids) {
				if (!ssid.services || index(ssid.services, service) < 0)
					continue;
				push(interfaces, interface);
			}
		}

		return uniq(interfaces);
	},

	lookup_ssids: function(service) {
		let ssids = [];

		for (let interface in state.interfaces) {
			if (!interface.ssids)
				continue;
			for (let ssid in interface.ssids) {
				if (!ssid.services || index(ssid.services, service) < 0)
					continue;
				push(ssids, ssid);
			}
		}

		return ssids;
	},

	lookup_ethernet: function(service) {
		let ethernets = [];

		for (let ethernet in state.ethernet) {
			if (!ethernet.services || index(ethernet.services, service) < 0)
				continue;
			push(ethernets, ethernet);
		}

		return ethernets;
	},

	lookup_services: function() {
		let rv = [];

		for (let incfile in fs.glob(topdir + '/templates/services/*.uc')) {
			let m = match(incfile, /^.+\/([^\/]+)\.uc$/);

			if (m)
				push(rv, m[1]);
		}

		return rv;
	},

	lookup_metrics: function() {
		let rv = [];

		for (let incfile in fs.glob(topdir + '/templates/metric/*.uc')) {
			let m = match(incfile, /^.+\/([^\/]+)\.uc$/);

			if (m)
				push(rv, m[1]);
		}

		return rv;
	}
};

/**
 * @class uCentral.local_profile
 * @classdesc
 *
 * The local profile utility class provides access to the uCentral runtome
 * profile information.
 */

/** @lends uCentral.local_profile.prototype */

let local_profile = {
	/**
	 * Retrieve the local uCentral profile data.
	 *
	 * Parses the local uCentral profile JSON data and returns the
	 * resulting object.
	 *
	 * @return {?object}
	 * Returns an object containing the profile data or `null` on error.
	 */
	get: function() {
		let profile_file = fs.open("/etc/ucentral/profile.json");

		if (profile_file) {
			let profile = json(profile_file.read("all"));

			profile_file.close();

			return profile;
		}
		return null;
	}
};

/**
 * @class uCentral.files
 * @classdesc
 *
 * The files utility class manages non-uci file attachments which are
 * produced during schema rendering.
 */

/** @lends uCentral.files.prototype */

let files = {
	/** @private */
	files: {},

	/**
	 * The base directory for file attachments.
	 *
	 * @readonly
	 */
	basedir: '/tmp/ucentral',

	/**
	 * Escape the given string.
	 *
	 * Escape any slash and tilde characters in the given string to allow
	 * using it as part of a JSON pointer expression.
	 *
	 * @param {string} s  The string to escape
	 * @returns {string}  The escaped string
	 */
	escape: function(s) {
		return replace(s, /[~\/]/g, m => (m == '~' ? '~0' : '~1'));
	},

	/**
	 * Add a named file attachment.
	 *
	 * Stores the given content in a file at the given path. Expands the
	 * path relative to the `basedir` if it is not absolute.
	 *
	 * @param {string} path  The file path
	 * @param {*} content    The content to store
	 */
	add_named: function(path, content) {
		if (index(path, '/') != 0)
			path = this.basedir + '/' + path;

		this.files[path] = content;
	},

	/**
	 * Add an anonymous file attachment.
	 *
	 * Stores the given content in a file with a random name derived from
	 * the given location pointer and name hint.
	 *
	 * @param {string} location  The current location within the state we're traversing
	 * @param {string} name      The name hint
	 * @param {*} content        The content to store
	 *
	 * @returns {string}
	 * Returns the generated random file path.
	 */
	add_anonymous: function(location, name, content) {
		let path = this.basedir + '/' + this.escape(location) + '/' + this.escape(name);

		this.files[path] = content;

		return path;
	},

	/**
	 * Recursively create the parent directories of the given path.
	 *
	 * Recursively creates the parent directory structure of the given
	 * path and places any error messages in the given logs array.
	 *
	 * @param {array} logs   The array to store log messages into
	 * @param {string} path  The path to create directories for
	 * @return {boolean}
	 * Returns `true` if the parent directories were successfully created
	 * or did already exist, returns `false` in case an error occurred.
	 */
	mkdir_path: function(logs, path) {
		assert(index(path, '/') == 0, "Expecting absolute path");

		let segments = split(path, '/'),
		    tmppath = shift(segments);

		for (let i = 0; i < length(segments) - 1; i++) {
			tmppath += '/' + segments[i];

			let s = fs.stat(tmppath);

			if (s != null && s.type == 'directory')
				continue;

			if (fs.mkdir(tmppath))
				continue;

			push(logs, sprintf("[E] Unable to mkdir() path '%s': %s", tmppath, fs.error()));

			return false;
		}

		return true;
	},

	/**
	 * Write the staged file attachement contents to the filesystem.
	 *
	 * Writes the staged attachment contents that were gathered during state
	 * rendering to the file system and places any encountered errors into
	 * the logs array.
	 *
	 * @param {array} logs  The array to store error messages into
	 * @return {boolean}
	 * Returns `true` if all attachments were written succefully, returns
	 * `false` if one or more attachments could not be written.
	 */
	write: function(logs) {
		let success = true;

		for (let path, content in this.files) {
			if (!this.mkdir_path(logs, path)) {
				success = false;
				continue;
			}

			let f = fs.open(path, "w");

			if (f) {
				f.write(content);
				f.close();
			}
			else {
				push(logs, sprintf("[E] Unable to open() path '%s' for writing: %s", path, fs.error()));
				success = false;
			}
		}

		return success;
	}
};

/**
 * @class uCentral.shell
 * @classdesc
 *
 * The shell utility class provides high level abstractions for various
 * shell interaction tasks.
 */

/** @lends uCentral.shell.prototype */

let shell = {
	/**
	 * Set a random root password.
	 *
	 * Generate a random passphrase and set it as root password,
	 * do not change the password if a random password has been
	 * set already since the last reboot.
	 */
	password: function(random) {
		let passwd = "openwifi";

		if (random) {
			let math = require("math");
			passwd = '';
			for (let i = 0; i < 32; i++) {
				let r = math.rand() % 62;
				if (r < 10)
					passwd += r;
			else if (r < 36)
					passwd += sprintf("%c", 55 + r);
				else
					passwd += sprintf("%c", 61 + r);
			}
		}
		system("(echo " + passwd + "; sleep 1; echo " + passwd + ") | passwd root");
		conn.call("ucentral", "password", { passwd });
	}
};

/**
 * @class uCentral.routing_table
 * @classdesc
 *
 * The routing table utility class allows querying system routing tables.
 */

/** @lends uCentral.routing_table.prototype */

let routing_table = {
	used_tables: {},

	next: 1,

	/**
	 * Allocate a route table index for the given ID
	 *
	 * @param {string} id  The ID to lookup or reserve
	 * @returns {number} The table number allocated for the given ID
	 */
	get: function(id) {
		if (!this.used_tables[id])
			this.used_tables[id] = this.next++;
		return this.used_tables[id];
	}
};

/**
 * @class uCentral.captive
 * @classdesc
 *
 * The captive portal utility class allows assigning consecutive names to wifi-ifaces.
 */

/** @lends uCentral.captive.prototype */

let captive = {
	interfaces: {},

	next: 0,

	/**
	 * Allocate a route table index for the given ID
	 *
	 * @param {string} id  The ID to lookup or reserve
	 * @returns {number} The table number allocated for the given ID
	 */
	get: function(name) {
		let iface = this.next++;
		push(this.interfaces[name].iface, iface);
		return iface;
	},

	/**
	 * Add an interface
	 */
	interface: function(name, config) {
		this.interfaces[name] = {};
		for (let k, v in config)
			this.interfaces[name][k] = v;
		this.interfaces[name].iface = [];
	},
};

/**
 * @class uCentral.latency
 * @classdesc
 *
 * The latency measurement utility class allows registering IPs and URLs that will
 * get pinged periodically to find out the latency.
 */

/** @lends uCentral.routing_table.prototype */

let latency = {
	ipv4: [],

	ipv6: [],

	/**
	 * Add an IP/URL that shall have its latency measured
	 *
	 * @param {string} ip/url  The IP/URL to measure
	 * @param {number} network family
	 */
	add: function(host, family) {
		switch(family) {
		case 4:
			push(this.ipv4, host);
			break;
		case 6:
			push(this.ipv6, host);
			break;
		}
	},

	/**
	 * create the files in /tmp that hold the hosts that we want to measure
	 */
	write: function() {
		for (let family in ['ipv4', 'ipv6']) {
			let file = fs.open(`/tmp/latency.${family}`, 'w');
			if (!file) {
				warn(`failed to open /tmp/latency.${family}\n`);
				continue;
			}
			for (let ip in this[family])
				file.write(ip + '\n');
			file.close();
		}
	},
};

/**
 * @constructs
 * @name uCentral
 * @classdesc
 *
 * The uCentral namespace is not an actual class but merely a virtual
 * namespace for documentation purposes.
 *
 * From the perspective of a template author, the uCentral namespace
 * is the global root level scope available to embedded code, so
 * methods like `uCentral.b()` or `uCentral.info()` or utlity classes
 * like `uCentral.files` or `uCentral.wiphy` are available to templates
 * as `b()`, `info()`, `files` and `wiphy` respectively.
 */
return /** @lends uCentral.prototype */ {
	render: function(state, logs) {
		logs = logs || [];

		/** @lends uCentral.prototype */
		return render('templates/toplevel.uc', {
			b,
			s,
			tryinclude,
			state,

			/** @member {uCentral.wiphy} */
			wiphy,

			/** @member {uCentral.ethernet} */
			ethernet,

			/** @member {uCentral.ipcalc} */
			ipcalc,

			/** @member {uCentral.services} */
			services,

			/** @member {uCentral.local_profile} */
			local_profile,
			location: '/',
			cursor,
			capab,
			restrict,

			/** @member {uCentral.files} */
			files,

			/** @member {uCentral.latency} */
			latency,

			/** @member {uCentral.shell} */
			shell,

			/** @member {uCentral.routing_table} */
			routing_table,
			serial,

			/** @member {uCentral.captive} */
			captive,

			/**
			 * Emit a warning message.
			 *
			 * @memberof uCentral.prototype
			 * @param {string} fmt  The warning message format string
			 * @param {...*} args	Optional format arguments
			 */
			warn: (fmt, ...args) => push(logs, sprintf("[W] (In %s) ", location || '/') + sprintf(fmt, ...args)),

			/**
			 * Emit an error message.
			 *
			 * @memberof uCentral.prototype
			 * @param {string} fmt  The warning message format string
			 * @param {...*} args	Optional format arguments
			 */
			error: (fmt, ...args) => push(logs, sprintf("[E] (In %s) ", location || '/') + sprintf(fmt, ...args)),

			/**
			 * Emit an informational message.
			 *
			 * @memberof uCentral.prototype
			 * @param {string} fmt  The information message format string
			 * @param {...*} args	Optional format arguments
			 */
			info: (fmt, ...args) => push(logs, sprintf("[!] (In %s) ", location || '/') + sprintf(fmt, ...args))
		});
	},

	write_files: function(logs) {
		logs = logs || [];

		return files.write(logs);
	},

	files_state: function() {
		return files.files;
	},

	services_state: function() {
		return services.state;
	}
};
