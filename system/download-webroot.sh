#!/bin/sh
url=$1
hash=$2

check_hash() {
        [ -f /etc/ucentral/web-root.tar.gz ] && {
                sha256=`sha256sum /etc/ucentral/web-root.tar.gz | cut -d" " -f1`
                [ $sha256 != $hash ] && rm /etc/ucentral/web-root.tar.gz
        }
}

check_hash

[ -f /etc/ucentral/web-root.tar.gz ] || wget $url -O /etc/ucentral/web-root.tar.gz

check_hash
