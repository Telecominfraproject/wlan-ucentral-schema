{%
	let admin_ui = state.services?.admin_ui;
	if (!admin_ui?.wifi_ssid)
		return;

	let interface = {
		admin_ui: true,
		name: 'Admin-UI',
		role: 'downstream',
		auto_start: 0,
		services: [ 'ssh', 'http' ],
		ipv4: {
			addressing: 'static',
			subnet: '10.254.254.1/24',
			dhcp: {
				lease_first: 10,
				lease_count: 10,
				lease_time: '6h'
			}
		},
		ssids: [
			{
				name: admin_ui.wifi_ssid,
				wifi_bands: [ '2G', '5G' ],
				bss_mode: 'ap',
				encryption: {
					proto: 'none'
				}
			}
		],
	};

	if (admin_ui.wifi_bands)
		interface.ssids[0].wifi_bands = admin_ui.wifi_bands;
	if (admin_ui.wifi_key) {
		interface.ssids[0].encryption.proto = 'psk2';
		interface.ssids[0].encryption.key = admin_ui.wifi_key;
	}
	push(state.interfaces, interface);
%}

set state.ui.offline_trigger={{ admin_ui.offline_trigger }}
