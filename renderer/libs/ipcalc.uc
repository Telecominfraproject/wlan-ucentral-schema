export let ipcalc = {
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
	},

	/**
	 * Simple generate_prefix for ip-collide compatibility
	 * Uses hardcoded IPv4 defaults instead of state globals
	 */
	generate_prefix_simple: function(available, template) {
		let prefix = match(template, /^(auto|[0-9a-fA-F:.]+)\/([0-9]+)$/);

		if (prefix && prefix[1] == 'auto') {
			let pool = match(available, /^([0-9a-fA-F:.]+)\/([0-9]+)$/);

			if (prefix[2] < pool[2]) {
				return null;
			}

			let available_prefixes = 1 << (prefix[2] - pool[2]),
			    prefix_mask = this.convert_bits_to_mask(prefix[2]),
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

			return null;
		}

		return template;
	}
};