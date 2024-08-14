#!/bin/sh

install() {
    cp bin/setup /usr/bin/setup
    chmod a+x /usr/bin/setup
    cp bin/setup-env /usr/bin/setup-env
    chmod a+x /usr/bin/setup-env

    cp lib/setup-config /usr/lib/setup-config

    if [ ! -f /etc/setup.conf ]; then
        cp etc/setup.conf.sample /etc/setup.conf
    fi

    echo "Done"
}

uninstall() {
    rm -f /usr/bin/setup
    rm -f /usr/bin/setup-env

    rm -f /usr/lib/setup-config

    echo "Done"
}

usage() {
    /bin/echo -e "Usage:"
    /bin/echo -e "\t./setup.sh install"
    /bin/echo -e "\t./setup.sh uninstall"
}

if [ "$#" -ne 1 ]; then
    usage
    exit 1
elif [ "$1" = "install" ]; then
    install
elif [ "$1" = "uninstall" ]; then
    uninstall
else
    usage
    exit 1
fi
