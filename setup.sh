#!/bin/sh

install() {
    cp bin/setup /usr/bin/setup
    chmod a+x /usr/bin/setup
    cp bin/setup-env /usr/bin/setup-env
    chmod a+x /usr/bin/setup-env

    mkdir -p /usr/lib/setup
    cp lib/setup/config /usr/lib/setup/config

    if [ ! -f /etc/setup.conf ]; then
        if [ "$init_system" = "systemd" ]; then
            cp etc/setup.conf.systemd.sample /etc/setup.conf
        elif [ "$init_system" = "sysvinit" ]; then
            cp etc/setup.conf.sysvinit.sample /etc/setup.conf
        fi
    fi

    echo "Done"
}

uninstall() {
    rm -f /usr/bin/setup
    rm -f /usr/bin/setup-env

    rm -f /usr/lib/setup/config

    # Avoid removing /etc/setup.conf and preserve relative administration efforts

    echo "Done"
}

usage() {
    /bin/echo -e "Usage:"
    /bin/echo -e "\t./setup.sh install <init_system>"
    /bin/echo -e "\t./setup.sh uninstall"
    /bin/echo -e "Arguments:"
    /bin/echo -e "\tinit_system\tthe value be systemd or sysvinit"
}

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    usage
    exit 1
elif [ "$1" = "install" ]; then
    if [ "$2" = "systemd" ] || [ "$2" = "sysvinit" ]; then
        init_system="$2"
        install
    else
        usage
        exit 1
    fi
elif [ "$1" = "uninstall" ] && [ "$2" = "" ]; then
    uninstall
else
    usage
    exit 1
fi
