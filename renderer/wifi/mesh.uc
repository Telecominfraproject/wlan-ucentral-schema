let nl = require("nl80211");
let def = nl.const;

const NL80211_IFTYPE_MESH_POINT = 7;

function wif_get(wdev) {
        let res = nl.request(def.NL80211_CMD_GET_INTERFACE, def.NLM_F_DUMP);

        if (res === false)
                warn("Unable to lookup interfaces: " + nl.error() + "\n");

        return res;
}

function lookup_mesh() {
	let wifs = wif_get();
	let rv = {};
	for (let wif in wifs) {
		if (!wif.wiphy_freq || wif.iftype != NL80211_IFTYPE_MESH_POINT)
			continue;
		let w = [];
		let params = { dev: wif.ifname };
		let mpath = nl.request(def.NL80211_CMD_GET_MPATH, def.NLM_F_DUMP, params);
		for (let path in mpath) {
			push(w, {
				destinantion: path.mac,
				next_hop: path.mpath_next_hop,
				metric: path.mpath_info.metric,
				expire: path.mpath_info.expire,
				discovery_timeout: path.mpath_info.discovery_timeout,
				discovery_retries: path.mpath_info.discovery_retries,
				hop_count: path.mpath_info.hop_count,
			});
		}
		rv[wif.ifname] = w;
	}
	return rv;
}

return lookup_mesh();
