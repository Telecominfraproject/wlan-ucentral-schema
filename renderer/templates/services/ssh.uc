{%
let interfaces = services.lookup_interfaces("ssh");
let enable = length(interfaces);

if (restrict.ssh && enable) {
	warn('SSH is restricted');
	enable = false;
}

services.set_enabled("dropbear", enable);
if (!enable)
	return;
files.add_named("/etc/dropbear/authorized_keys", join("\n", ssh.authorized_keys || []) + "\n");
%}

# SSH service configuration

set dropbear.@dropbear[-1].enable={{ b(enable) }}
set dropbear.@dropbear[-1].Port={{ s(ssh.port) }}
set dropbear.@dropbear[-1].PasswordAuth={{ b(ssh.password_authentication) }}

{% for (let interface in interfaces): %}
{%    let name = ethernet.calculate_name(interface) %}

add firewall rule
set firewall.@rule[-1].name='Allow-ssh-{{ name }}'
set firewall.@rule[-1].src='{{ name }}'
set firewall.@rule[-1].dest_port='{{ ssh.port }}'
set firewall.@rule[-1].proto='tcp'
set firewall.@rule[-1].target='ACCEPT'
{% endfor %}
