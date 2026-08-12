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

		netdev: {},

		next: 0,

		/**
		 * Record the kernel netdev backing a captive capable interface.
		 *
		 * netifd names an auto created bridge br-<network>, while the bridge-vlan
		 * path yields an explicit 8021q device named <network>. spotfilter resolves
		 * class device_macaddr via SIOCGIFHWADDR, so it needs the real netdev name.
		 *
		 * @param {string} name  The logical interface name, e.g. down2v0
		 * @param {string} dev   The kernel netdev name, e.g. br-down2v0
		 */
		set_netdev: function(name, dev) {
			this.netdev[name] = dev;
		},

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
