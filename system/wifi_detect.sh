#!/bin/sh

. /lib/functions.sh

iface_del() {
        uci delete wireless.$1
}

rm /etc/config/wireless
wifi config
config_load wireless
config_foreach iface_del wifi-iface
config_foreach iface_del wifi-vlan
uci commit wireless
cp /etc/config/wireless /tmp/config-shadow/
