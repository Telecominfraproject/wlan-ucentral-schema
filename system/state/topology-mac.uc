import { readfile, lsdir, stat, popen, glob } from 'fs';

// Global storage for MAC entries
let macEntries = {};

// Parse MAC address from different formats
function normalizeMacAddress(macStr) {
    if (!macStr) return null;
    
    // Remove any whitespace and convert to lowercase
    macStr = trim(lc(macStr));
    
    // Handle different formats: aa:bb:cc:dd:ee:ff, aabbccddeeff, aa-bb-cc-dd-ee-ff
    if (length(macStr) == 12) {
        // Insert colons for aabbccddeeff format
        macStr = sprintf('%s:%s:%s:%s:%s:%s',
            substr(macStr, 0, 2), substr(macStr, 2, 2),
            substr(macStr, 4, 2), substr(macStr, 6, 2),
            substr(macStr, 8, 2), substr(macStr, 10, 2)
        );
    } else if (index(macStr, '-') >= 0) {
        // Convert aa-bb-cc-dd-ee-ff to aa:bb:cc:dd:ee:ff
        macStr = replace(macStr, '-', ':');
    }
    
    // Validate MAC format
    if (match(macStr, /^[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}$/)) {
        return macStr;
    }
    
    return null;
}

// Get or create MAC entry
function getMacEntry(macAddr) {
    if (!macAddr) return null;
    
    macAddr = normalizeMacAddress(macAddr);
    if (!macAddr) return null;
    
    if (!macEntries[macAddr]) {
        macEntries[macAddr] = {
            interface: null,
            last_seen: 0,
            ipv4: [],
            ipv6: [],
            fdb: [],
            offline: false
        };
    }
    
    return macEntries[macAddr];
}

// Parse neighbor table (/proc/net/arp for IPv4, /proc/net/neighbour for IPv6)
function parseNeighborTable() {
    // Parse IPv4 ARP table
    try {
        let arpContent = readfile('/proc/net/arp');
        if (arpContent) {
            let lines = split(trim(arpContent), '\n');
            // Skip header line
            for (let i = 1; i < length(lines); i++) {
                let parts = split(trim(lines[i]), /\s+/);
                if (length(parts) >= 6) {
                    let ip = parts[0];
                    let mac = parts[3];
                    let iface = parts[5];
                    let flags = parts[2];
                    
                    // Only include complete entries (0x2 = NUD_REACHABLE/NUD_STALE)
                    if (mac != '00:00:00:00:00:00' && flags != '0x0') {
                        let entry = getMacEntry(mac);
                        if (entry) {
                            if (index(entry.ipv4, ip) == -1) {
                                push(entry.ipv4, ip);
                            }
                            if (!entry.interface && iface) {
                                entry.interface = iface;
                            }
                        }
                    }
                }
            }
        }
    } catch (e) {
        // ARP table parsing failed
    }
    
    // Parse IPv6 neighbor table
    try {
        let neighContent = readfile('/proc/net/ndisc_cache');
        if (neighContent) {
            let lines = split(trim(neighContent), '\n');
            // Skip header
            for (let i = 1; i < length(lines); i++) {
                let parts = split(trim(lines[i]), /\s+/);
                if (length(parts) >= 4) {
                    let ip = parts[0];
                    let iface = parts[1];
                    let mac = parts[3];
                    
                    if (mac != '00:00:00:00:00:00' && mac != '(none)') {
                        let entry = getMacEntry(mac);
                        if (entry) {
                            if (index(entry.ipv6, ip) == -1) {
                                push(entry.ipv6, ip);
                            }
                            if (!entry.interface && iface) {
                                entry.interface = iface;
                            }
                        }
                    }
                }
            }
        }
    } catch (e) {
        // IPv6 neighbor table parsing failed - try alternative method
        try {
            // Alternative: use ip command
            let proc = popen('ip -6 neigh show 2>/dev/null', 'r');
            if (proc) {
                let line;
                while ((line = proc.read('line'))) {
                    // Format: "fe80::1 dev eth0 lladdr aa:bb:cc:dd:ee:ff REACHABLE"
                    let match_result = match(trim(line), /^(\S+)\s+dev\s+(\S+)\s+lladdr\s+([a-f0-9:]{17})\s+\S+/);
                    if (match_result && length(match_result) >= 4) {
                        let ip = match_result[1];
                        let iface = match_result[2];
                        let mac = match_result[3];
                        
                        let entry = getMacEntry(mac);
                        if (entry) {
                            if (index(entry.ipv6, ip) == -1) {
                                push(entry.ipv6, ip);
                            }
                            if (!entry.interface && iface) {
                                entry.interface = iface;
                            }
                        }
                    }
                }
                proc.close();
            }
        } catch (e2) {
            // Both methods failed
        }
    }
}

// Parse bridge forwarding database
function parseBridgeFdb() {
    // Read bridge FDB from /sys/class/net/*/brif/*/fdb or use bridge command
    
    try {
        // Method 1: Use bridge command if available
        let proc = popen('bridge fdb show 2>/dev/null', 'r');
        if (proc) {
            let line;
            while ((line = proc.read('line'))) {
                // Format: "aa:bb:cc:dd:ee:ff dev eth1 master br0 permanent"
                let match_result = match(trim(line), /^([a-f0-9:]{17})\s+dev\s+(\S+)/);
                if (match_result && length(match_result) >= 3) {
                    let mac = match_result[1];
                    let iface = match_result[2];
                    
                    // Skip local/permanent entries and multicast
                    if (!match(line, /permanent/) && !match(line, /static/) && 
                        !match(mac, /^01:/) && !match(mac, /^33:/)) {
                        let entry = getMacEntry(mac);
                        if (entry) {
                            if (index(entry.fdb, iface) == -1) {
                                push(entry.fdb, iface);
                            }
                            if (!entry.interface && iface) {
                                entry.interface = iface;
                            }
                        }
                    }
                }
            }
            proc.close();
        }
    } catch (e) {
        // Bridge command failed, try alternative methods
        
        try {
            // Method 2: Read bridge FDB files directly
            let bridgeGlob = glob('/sys/class/net/*/bridge/');
            for (let bridgePath in bridgeGlob) {
                let bridge = replace(bridgePath, /.*\/([^\/]+)\/bridge\//, '$1');
                let fdbPath = replace(bridgePath, 'bridge/', 'brforward');
                
                try {
                    let fdbContent = readfile(fdbPath);
                    if (fdbContent) {
                        // Parse binary FDB format - this is complex, skip for now
                        // Alternative: check brif interfaces
                        let brifPath = replace(bridgePath, 'bridge', 'brif');
                        let brifs = lsdir(brifPath);
                        
                        for (let iface in brifs) {
                            if (iface != '.' && iface != '..') {
                                // For each bridge interface, we could check for MAC learning
                                // This is complex without direct FDB access
                            }
                        }
                    }
                } catch (e2) {
                    // This bridge has no FDB or is not accessible
                }
            }
        } catch (e3) {
            // Filesystem method also failed
        }
    }
}

// Parse DHCP leases (similar to what's in network.uc)
function parseDhcpLeases() {
    try {
        let content = readfile("/tmp/dhcp.leases");
        if (content) {
            let lines = split(trim(content), '\n');
            for (let line in lines) {
                let tokens = split(line, " ");
                
                if (length(tokens) >= 4) {
                    let assigned = tokens[0];
                    let mac = tokens[1];
                    let ip = tokens[2];
                    let hostname = tokens[3];
                    
                    let entry = getMacEntry(mac);
                    if (entry) {
                        if (index(entry.ipv4, ip) == -1) {
                            push(entry.ipv4, ip);
                        }
                        // Could add hostname info if needed
                    }
                }
            }
        }
    } catch (e) {
        // DHCP leases parsing failed
    }
}

// Get interface from ARP/neighbor tables for MAC resolution
function findMacInterface(mac) {
    // This would be called during the neighbor parsing
    // The interface is already set during parseNeighborTable()
    return null;
}

// Calculate last seen time (in real implementation, this would use timestamps)
function calculateLastSeen(mac) {
    // In the original C code, this uses stored timestamps
    // For now, we'll return 0 for active entries
    return 0;
}

// Main function to gather MAC topology information
export function getTopologyMacInfo() {
    // Clear previous data
    macEntries = {};
    
    // Gather data from various sources
    parseNeighborTable();
    parseBridgeFdb();
    parseDhcpLeases();
    
    // Build final result matching the original format
    let result = {};
    
    for (let mac, entry in macEntries) {
        // Only include entries with some meaningful data
        if (length(entry.ipv4) > 0 || length(entry.ipv6) > 0 || length(entry.fdb) > 0 || entry.interface) {
            let macInfo = {};
            
            if (entry.interface) {
                macInfo.interface = entry.interface;
            }
            
            // Calculate last seen (simplified)
            macInfo.last_seen = calculateLastSeen(mac);
            
            if (length(entry.ipv4) > 0) {
                macInfo.ipv4 = entry.ipv4;
            }
            
            if (length(entry.ipv6) > 0) {
                macInfo.ipv6 = entry.ipv6;
            }
            
            if (length(entry.fdb) > 0) {
                macInfo.fdb = entry.fdb;
            }
            
            result[mac] = macInfo;
        }
    }
    
    return result;
};