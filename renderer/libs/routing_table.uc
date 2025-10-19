// Routing table management library

"use strict";

/**
 * @class uCentral.routing_table
 * @classdesc
 *
 * The routing table utility class allows querying system routing tables.
 */

/** @lends uCentral.routing_table.prototype */

export function create_routing_table() {
	return {
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
};
