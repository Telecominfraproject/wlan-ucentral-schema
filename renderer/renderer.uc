// UCI batch output master template

"use strict";

let uci = require("uci");
let ubus = require("ubus");
let fs = require("fs");
let math = require("math");
import { ipcalc } from 'libs.ipcalc';
import { create_ethernet } from 'libs/ethernet.uc';
import { create_wiphy } from 'libs/wiphy.uc';
import { create_routing_table } from 'libs/routing_table.uc';
import { create_captive } from 'libs/captive.uc';
import { 
	b, s, uci_cmd, uci_set_string, uci_set_boolean, uci_set_number, uci_set_raw,
	uci_list_string, uci_list_number, uci_section, uci_named_section, 
	uci_set, uci_list, uci_output, uci_comment
} from 'libs/uci_helpers.uc';

let cursor = uci ? uci.cursor() : null;
let conn = ubus ? ubus.connect() : null;

let capabfile = fs.open("/etc/ucentral/capabilities.json", "r");
let capab = capabfile ? json(capabfile.read("all")) : null;

let board = fs.readfile('/etc/board.json');
if (board)
	board = json(board);

let pipe = fs.popen('fw_printenv developer');
let developer = replace(pipe.read("all"), '\n', '');
pipe.close();
let restrict = {};
if (developer != 'developer=1') {
	let restrictfile = fs.open("/etc/ucentral/restrictions.json", "r");
	restrict = restrictfile ? json(restrictfile.read("all")) : {};
}

let default_config = fs.readfile('/etc/ucentral/ucentral.defaults');
default_config = default_config ? json(default_config) : {};
default_config.country ??= 'US';

let serial = cursor.get("ucentral", "config", "serial");

assert(cursor, "Unable to instantiate uci");
assert(conn, "Unable to connect to ubus");
assert(capab, "Unable to load capabilities");

let topdir = sourcepath(0, true);


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


// Create wiphy instance using shared library
let wiphy = create_wiphy(cursor, warn);
// Set the real PHY data in renderer
wiphy.phys = require("wifi.phy");

// Create ethernet instance using shared library
let ethernet = create_ethernet(capab, fs, null);


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
			else if (state == 'no-restart')
				this.state[name] = 'no-restart';
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

	lookup_ssids_by_mpsk: function() {
		let mpsk = false;

		for (let interface in state.interfaces) {
			if (!interface.ssids)
				continue;
			for (let ssid in interface.ssids) {
				if (!ssid?.enhanced_mpsk)
					continue;
				if ((ssid?.encryption?.proto && type(ssid.encryption.proto) == 'string' &&
				    ssid.encryption.proto == "mpsk-radius") ||
				    (type(ssid.multi_psk) == 'bool' && ssid.multi_psk))
					mpsk = true;
				else if (!length(ssid.multi_psk))
					continue;
				mpsk = true;
			}
		}

		return mpsk;
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
	},

	/**
	 * Set system password
	 */
	system_password: function(passwd) {
		system("(echo " + passwd + "; sleep 1; echo " + passwd + ") | passwd root");
		conn.call("ucentral", "password", { passwd });
	}
};

// Create routing table instance using shared library
let routing_table = create_routing_table();

// Create captive instance using shared library
let captive = create_captive();

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
			fs,

			b,
			s,
			tryinclude,
			state,

			// UCI helpers
			uci_cmd,
			uci_set_string,
			uci_set_boolean,
			uci_set_number,
			uci_set_raw,
			uci_list_string,
			uci_list_number,
			uci_section,
			uci_named_section,
			uci_set,
			uci_list,
			uci_output,
			uci_comment,

			/** @member {uCentral.wiphy} */
			wiphy,

			/** @member {uCentral.ethernet} */
			ethernet,

			/** @member {uCentral.ipcalc} */
			ipcalc,

			/** @member {uCentral.math} */
			math,

			/** @member {uCentral.services} */
			services,

			/** @member {uCentral.local_profile} */
			local_profile,
			location: '/',
			cursor,
			capab,
			restrict,
			default_config,

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
