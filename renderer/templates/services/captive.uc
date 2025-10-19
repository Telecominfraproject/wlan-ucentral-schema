{%
	// Helper functions
	function has_captive_service() {
		return services.is_present("spotfilter");
	}

	function get_captive_interfaces() {
		return services.lookup_interfaces_by_ssids("captive");
	}

	function has_captive_interfaces() {
		let interfaces = get_captive_interfaces();

		return length(interfaces) > 0;
	}

	function validate_single_interface() {
		let interfaces = get_captive_interfaces();

		if (length(interfaces) > 1) {
			warn('captive portal can only run on a single interface');
			return false;
		}
		return true;
	}

	function get_unique_interfaces() {
		let interfaces = get_captive_interfaces();

		return uniq(interfaces);
	}

	function is_downstream_interface(interface) {
		return interface.role == 'downstream';
	}

	// Configuration generation functions
	function generate_firewall_redirect(interface) {
		let name = ethernet.calculate_name(interface);
		let output = [];

		uci_section(output, 'firewall redirect');
		uci_set_string(output, 'firewall.@redirect[-1].name', 'Redirect-captive-' + name);
		uci_set_string(output, 'firewall.@redirect[-1].src', name);
		uci_set_string(output, 'firewall.@redirect[-1].src_dport', '80');
		uci_set_string(output, 'firewall.@redirect[-1].proto', 'tcp');
		uci_set_string(output, 'firewall.@redirect[-1].target', 'DNAT');
		uci_set_string(output, 'firewall.@redirect[-1].mark', '1/127');

		return uci_output(output);
	}

	function generate_firewall_rules(interface) {
		let name = ethernet.calculate_name(interface);
		let output = [];

		// Allow pre-captive rule
		uci_section(output, 'firewall rule');
		uci_set_string(output, 'firewall.@rule[-1].name', 'Allow-pre-captive-' + name);
		uci_set_string(output, 'firewall.@rule[-1].src', name);
		uci_set_string(output, 'firewall.@rule[-1].dest_port', '80');
		uci_set_string(output, 'firewall.@rule[-1].proto', 'tcp');
		uci_set_string(output, 'firewall.@rule[-1].target', 'ACCEPT');
		uci_set_string(output, 'firewall.@rule[-1].mark', '1/127');

		// Allow captive rule
		uci_section(output, 'firewall rule');
		uci_set_string(output, 'firewall.@rule[-1].name', 'Allow-captive-' + name);
		uci_set_string(output, 'firewall.@rule[-1].src', name);
		uci_set_string(output, 'firewall.@rule[-1].dest_port', '80');
		uci_set_string(output, 'firewall.@rule[-1].proto', 'tcp');
		uci_set_string(output, 'firewall.@rule[-1].target', 'ACCEPT');
		uci_set_string(output, 'firewall.@rule[-1].mark', '2/127');

		return uci_output(output);
	}

	function generate_downstream_firewall_rules(interface) {
		if (!is_downstream_interface(interface))
			return '';

		let name = ethernet.calculate_name(interface);
		let upstream_interface = ethernet.find_interface("upstream", interface.vlan.id);
		let output = [];

		// Drop pre-captive rule
		uci_section(output, 'firewall rule');
		uci_set_string(output, 'firewall.@rule[-1].name', 'Drop-pre-captive-' + name);
		uci_set_string(output, 'firewall.@rule[-1].src', name);
		uci_set_string(output, 'firewall.@rule[-1].dest', upstream_interface);
		uci_set_string(output, 'firewall.@rule[-1].proto', 'any');
		uci_set_string(output, 'firewall.@rule[-1].target', 'DROP');
		uci_set_string(output, 'firewall.@rule[-1].mark', '1/127');

		// Firewall include
		uci_section(output, 'firewall include');
		uci_set_string(output, 'firewall.@include[-1].type', 'nftables');
		uci_set_string(output, 'firewall.@include[-1].position', 'chain-post');
		uci_set_string(output, 'firewall.@include[-1].path', '/usr/share/uspot/firewall.nft');
		uci_set_string(output, 'firewall.@include[-1].chain', 'mangle_postrouting');

		return uci_output(output);
	}

	function generate_uhttpd_config() {
		let output = [];

		uci_section(output, 'uhttpd uhttpd');
		uci_set_string(output, 'uhttpd.@uhttpd[-1].redirect_https', '0');
		uci_set_string(output, 'uhttpd.@uhttpd[-1].rfc1918_filter', '1');
		uci_set_string(output, 'uhttpd.@uhttpd[-1].max_requests', '5');
		uci_set_string(output, 'uhttpd.@uhttpd[-1].max_connections', '100');
		uci_set_string(output, 'uhttpd.@uhttpd[-1].cert', '/etc/uhttpd.crt');
		uci_set_string(output, 'uhttpd.@uhttpd[-1].key', '/etc/uhttpd.key');
		uci_set_string(output, 'uhttpd.@uhttpd[-1].script_timeout', '60');
		uci_set_string(output, 'uhttpd.@uhttpd[-1].network_timeout', '30');
		uci_set_string(output, 'uhttpd.@uhttpd[-1].http_keepalive', '20');
		uci_set_string(output, 'uhttpd.@uhttpd[-1].tcp_keepalive', '1');
		uci_set_string(output, 'uhttpd.@uhttpd[-1].no_dirlists', '1');
		uci_list_string(output, 'uhttpd.@uhttpd[-1].listen_http', '0.0.0.0:80');
		uci_list_string(output, 'uhttpd.@uhttpd[-1].listen_http', '[::]:80');
		uci_set_string(output, 'uhttpd.@uhttpd[-1].home', '/tmp/ucentral/www-uspot');
		uci_list_string(output, 'uhttpd.@uhttpd[-1].ucode_prefix', '/hotspot=/usr/share/uspot/handler.uc');
		uci_list_string(output, 'uhttpd.@uhttpd[-1].ucode_prefix', '/logoff=/usr/share/uspot/handler.uc');
		uci_list_string(output, 'uhttpd.@uhttpd[-1].ucode_prefix', '/logout=/usr/share/uspot/handler.uc');
		uci_list_string(output, 'uhttpd.@uhttpd[-1].ucode_prefix', '/cpd=/usr/share/uspot/handler-cpd.uc');
		uci_list_string(output, 'uhttpd.@uhttpd[-1].ucode_prefix', '/env=/usr/share/uspot/handler-env.uc');
		uci_set_string(output, 'uhttpd.@uhttpd[-1].error_page', '/cpd');

		return uci_output(output);
	}

	function generate_captive_config() {
		if (!has_captive_service() || !has_captive_interfaces())
			return '';

		if (!validate_single_interface())
			return '';

		let interfaces = get_unique_interfaces();
		let sections = [];

		uci_comment(sections, '# generated by captive.uc');
		uci_comment(sections, '### generate Captive Portal firewall rules');

		// Generate firewall configuration for each interface
		for (let interface in interfaces) {
			let redirect_config = generate_firewall_redirect(interface);
			if (redirect_config)
				push(sections, redirect_config);

			let rules_config = generate_firewall_rules(interface);
			if (rules_config)
				push(sections, rules_config);

			let downstream_config = generate_downstream_firewall_rules(interface);
			if (downstream_config)
				push(sections, downstream_config);
		}

		uci_comment(sections, '### generate Captive Portal HTTP server configuration');
		let uhttpd_config = generate_uhttpd_config();
		if (uhttpd_config)
			push(sections, uhttpd_config);

		return uci_output(sections);
	}

	// Main logic
	if (!has_captive_service())
		return;

	let enable = has_captive_interfaces() && validate_single_interface();
	services.set_enabled("spotfilter", enable);
	services.set_enabled("uspot", enable);

	if (!enable)
		return;
%}

{{ generate_captive_config() }}
