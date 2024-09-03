#!/bin/sh

install() {
    pre_install

    echo "Install: started"

    copy_files "$pkg_bin_dir" "$sys_bin_dir"
    copy_files "$pkg_lib_dir" "$sys_lib_dir"
    copy_files "$pkg_share_dir" "$sys_share_dir"
    copy_files "$pkg_etc_dir" "$sys_etc_dir"

    echo "Install: finished"
}

pre_install() {
    PKG_INIT_DIR="$init_system"
    if [ "$init_system" = "systemd" ]; then
        SYS_INIT_DIR="/lib/systemd/system"
    elif [ "$init_system" = "sysvinit" ]; then
        SYS_INIT_DIR="/etc/init.d"
    fi
    sed \
        -e "s;{PKG_INIT_DIR};$PKG_INIT_DIR;g" \
        -e "s;{SYS_INIT_DIR};$SYS_INIT_DIR;g" \
        "template/setup.conf.sample" \
        >"etc/setup.conf.sample"
}

uninstall() {
    # Check packages in system
    local packages=$(ls -1 /usr/lib/setup/packages)
    if [ ! -z "$packages" ]; then
        echo "Error: Cannot uninstall Setup.sh before uninstalling all of the packages."
        exit 1
    fi

    echo "Uninstall: started"

    remove_files "$pkg_bin_dir" "$sys_bin_dir"
    remove_files "$pkg_lib_dir" "$sys_lib_dir"
    remove_files "$pkg_share_dir" "$sys_share_dir"
    # Avoid removing /etc/setup.conf and preserve relative administration efforts

    echo "Uninstall: finished"
}

usage() {
    /bin/echo -e "Usage:"
    /bin/echo -e "\t./setup.sh install <init_system>"
    /bin/echo -e "\t./setup.sh uninstall"
    /bin/echo -e "\t./setup.sh version"
    /bin/echo -e "Arguments:"
    /bin/echo -e "\tinit_system\tthe value be systemd or sysvinit"
}

sys_bin_dir=/usr/bin
sys_lib_dir=/usr/lib
sys_share_dir=/usr/share
sys_etc_dir=/etc

. "lib/setup/common"
. "lib/setup/info"

dry_run=false

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
elif [ "$1" = "version" ]; then
    print_setup_version
else
    exit_with_usage
fi
