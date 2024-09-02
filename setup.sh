#!/bin/sh

install() {
    echo "Install: started"

    echo_and_run cp bin/setup /usr/bin/setup
    echo_and_run chmod a+x /usr/bin/setup
    echo_and_run cp bin/setup-env /usr/bin/setup-env
    echo_and_run chmod a+x /usr/bin/setup-env

    echo_and_run mkdir -p /usr/lib/setup
    echo_and_run cp lib/setup/config /usr/lib/setup/config

    if [ ! -f /etc/setup.conf ]; then
        if [ "$init_system" = "systemd" ]; then
            echo_and_run cp etc/setup.conf.systemd.sample /etc/setup.conf
        elif [ "$init_system" = "sysvinit" ]; then
            echo_and_run cp etc/setup.conf.sysvinit.sample /etc/setup.conf
        fi
    fi

    echo "Install: finished"
}

uninstall() {
    # Check packages in system
    local packages=$(ls -1 /usr/lib/setup/packages)
    if [ ! -z "$packages" ]; then
        echo "Error: Cannot uninstall Setup.sh before uninstalling all of the packages."
        exit 1
    fi

    echo "Uninstall: started"

    echo_and_run rm -f /usr/bin/setup
    echo_and_run rm -f /usr/bin/setup-env

    echo_and_run rm -f /usr/lib/setup/config

    # Avoid removing /etc/setup.conf and preserve relative administration efforts

    echo "Uninstall: finished"
}

echo_and_run() {
    local command="$@"

    echo "$command"
    $command
}

exit_with_usage() {
    usage
    exit 1
}

usage() {
    /bin/echo -e "Usage:"
    /bin/echo -e "\t./setup.sh install <init_system>"
    /bin/echo -e "\t./setup.sh uninstall"
    /bin/echo -e "Arguments:"
    /bin/echo -e "\tinit_system\tthe value be systemd or sysvinit"
}

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    exit_with_usage
elif [ "$1" = "install" ]; then
    if [ "$2" = "systemd" ] || [ "$2" = "sysvinit" ]; then
        init_system="$2"
        install
    else
        exit_with_usage
    fi
elif [ "$1" = "uninstall" ] && [ "$2" = "" ]; then
    uninstall
else
    exit_with_usage
fi
