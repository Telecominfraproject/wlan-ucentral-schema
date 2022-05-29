#!/usr/bin/ucode

let uci = require("uci").cursor();
let ubus = require("ubus").connect();
let status = ubus.call("network.interface", "dump");
let up = [];
let down = [];
let collision = false;

let ipcalc = {
	used_prefixes: [],

	convert_bits_to_mask: function(bits) {
		let width = 32,
		    mask = [];

		bits = width - bits;

		for (let i = width / 8; i > 0; i--) {
			let b = (bits < 8) ? bits : 8;
			mask[i - 1] = ~((1 << b) - 1) & 0xff;
			bits -= b;
		}

		return mask;
	},

	apply_mask: function(addr, mask) {
		return map(addr, (byte, i) => byte & mask[i]);
	},

	is_intersecting_prefix: function(addr1, bits1, addr2, bits2) {
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
		addr = split(addr, ".");
		for (let i = 0; i < length(this.used_prefixes); i += 2) {
			let addr2 = this.used_prefixes[i + 0],
			    mask2 = this.used_prefixes[i + 1];

			// printf('reserve_prefix %.J %J\n', addr2, addr);
			if (length(addr2) != length(addr))
				continue;

			if (this.is_intersecting_prefix(addr, mask, addr2, mask2))
				return false;
		}

		push(this.used_prefixes, addr, mask);

		return true;
	},

	generate_prefix: function(available, template) {
		let prefix = match(template, /^(auto|[0-9a-fA-F:.]+)\/([0-9]+)$/);

		if (prefix && prefix[1] == 'auto') {
			let pool = match(available, /^([0-9a-fA-F:.]+)\/([0-9]+)$/);

			if (prefix[2] < pool[2]) {
				printf("Interface IPv4 prefix size exceeds available allocation pool size");
				return NULL;
			}

			let available_prefixes = 1 << (prefix[2] - pool[2]),
			    prefix_mask = this.convert_bits_to_mask(prefix[2]),
			    address_base = iptoarr(pool[1]);

			// printf("generate %.J %.J\n", pool[1], address_base);

			for (let offset = 0; offset < available_prefixes; offset++) {
				if (this.reserve_prefix(pool[1], prefix[2])) {
					this.add_amount(address_base, 1);

					return arrtoip(address_base) + '/' + prefix[2];
				}

				for (let i = length(address_base), carry = 1; i > 0; i--) {
					let t = address_base[i - 1] + (~prefix_mask[i - 1] & 0xff) + carry;
					address_base[i - 1] = t & 0xff;
					carry = t >> 8;
				}
			}

			return NULL;
		}

		return template;
	},
};

uci.load("network");

for (let iface in status.interface) {
	if (!iface.up || !length(iface['ipv4-address']))
		continue;
	let role = split(iface.device, /[[:digit:]]/);
	switch (role[0]) {
	case 'up':
		push(up, iface);
		break;
	case 'down':
		push(down, iface);
		break;
	}
}

for (let iface in up)
	for (let addr in iface['ipv4-address'])
		ipcalc.reserve_prefix(addr.address, addr.mask);

for (let iface in down)
	for (let addr in iface['ipv4-address'])
		if (!ipcalc.reserve_prefix(addr.address, addr.mask)) {
			let auto = ipcalc.generate_prefix('192.168.0.0/16', 'auto/' + addr.mask, false);
			system(sprintf("logger ip-collide: collision detected on %s\n", iface.device));
			if (auto) {
				system(sprintf('logger ip-collide: moving from %s/%d to %s\n', addr.address, addr.mask, auto));
				uci.set('network', iface.device, 'ipaddr', auto);
			} else {
				system(sprintf('logger ip-collide: no free address available, shutting down device\n'));
				system(sprintf('ifconfig %s down', iface.device));
			}
			uci.set('network', iface.device, 'collision', time());
			collision = true;
		}

if (collision) {
	uci.commit();
	system('reload_config');
}
