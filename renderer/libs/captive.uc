// Captive portal management library

"use strict";

/**
 * @class uCentral.captive
 * @classdesc
 *
 * The captive portal utility class allows assigning consecutive names to wifi-ifaces.
 */

/** @lends uCentral.captive.prototype */

export function create_captive() {
	return {
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
};
