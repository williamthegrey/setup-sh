#!/bin/sh

install() {
    init_sys_dirs
    pre_install

    echo "Install: started"

    copy_files "$pkg_bin_dir" "$sys_bin_dir"
    copy_files "$pkg_lib_dir" "$sys_lib_dir"
    copy_files "$pkg_share_dir" "$sys_share_dir"
    copy_files "$pkg_etc_dir" "$sys_etc_dir"

    echo "Install: finished"
}

pre_install() {
    generate_bin_files
    generate_etc_files
}

generate_bin_files() {
    mkdir -p "$pkg_bin_dir"
    render_template "$pkg_bin_dir/setup" "SYS_ROOT_DIR=$sys_root_dir"
    render_template "$pkg_bin_dir/setup-env" "SYS_ROOT_DIR=$sys_root_dir"
}

generate_etc_files() {
    local pkg_init_dir="$init_system"
    local sys_init_dir
    if [ "$init_system" = "systemd" ]; then
        sys_init_dir="/lib/systemd/system"
    elif [ "$init_system" = "sysvinit" ]; then
        sys_init_dir="/etc/init.d"
    elif [ "$init_system" = "procd" ]; then
        sys_init_dir="/etc/init.d"
    fi

    mkdir -p "$pkg_etc_dir"
    render_template "$pkg_etc_dir/setup.conf.sample" \
        "SYS_ROOT_DIR=$sys_root_dir" \
        "PKG_INIT_DIR=$pkg_init_dir" \
        "SYS_INIT_DIR=$sys_init_dir"
}

render_template() {
    local template_file="$1"
    shift

    get_replace_options "$@" | xargs -d '\n' sed "template/$template_file" >"$template_file"
}

get_replace_options() {
    for entry in "$@"; do
        local key="${entry%%=*}"
        local value="${entry#*=}"
        printf "%s\n" "-e"
        echo "s;\${$key};$value;g"
    done
}

uninstall() {
    init_sys_dirs
    # Check packages in system
    local packages=$(ls -1 "$sys_pkgs_dir")
    if [ ! -z "$packages" ]; then
        echo "Error: Cannot uninstall Setup.sh before uninstalling all of the packages."
        exit 1
    fi

    echo "Uninstall: started"

    remove_files "$pkg_bin_dir" "$sys_bin_dir"
    remove_files "$pkg_lib_dir" "$sys_lib_dir"
    remove_files "$pkg_share_dir" "$sys_share_dir"
    # Avoid removing $sys_etc_dir/setup.conf and preserve relative administration efforts

    echo "Uninstall: finished"
}

usage() {
    /bin/echo -e "Usage:"
    /bin/echo -e "\t./setup.sh install <init_system> [--root-dir <dir>]"
    /bin/echo -e "\t./setup.sh uninstall [--root-dir <dir>]"
    /bin/echo -e "\t./setup.sh version"
    /bin/echo -e "Arguments:"
    /bin/echo -e "\tinit_system\tThe value can be: systemd|sysvinit|procd"
    /bin/echo -e "Options:"
    /bin/echo -e "\t--root-dir\tThe root dir of installation destionation"
}

init_sys_dirs() {
    sys_bin_dir="$sys_root_dir/usr/bin"
    sys_lib_dir="$sys_root_dir/usr/lib"
    sys_share_dir="$sys_root_dir/usr/share"
    sys_etc_dir="$sys_root_dir/etc"

    sys_pkgs_dir="$sys_root_dir/usr/lib/setup/packages"
}

parse_root_dir_arg() {
    if [ "$#" -gt 0 ]; then
        require_args "$#" 2
        if [ "$1" = "--root-dir" ]; then
            sys_root_dir="$2"
            shift 2

            refuse_args "$#"
        else
            exit_with_usage
        fi
    fi
}

. "lib/setup/common"
. "lib/setup/info"

dry_run=false

require_args "$#" 1
if [ "$1" = "install" ]; then
    shift

    require_args "$#" 1
    if [ "$1" = "systemd" ] || [ "$1" = "sysvinit" ] || [ "$1" = "procd" ]; then
        init_system="$1"
        shift

        parse_root_dir_arg "$@"

        install
    else
        exit_with_usage
    fi
elif [ "$1" = "uninstall" ]; then
    shift

    parse_root_dir_arg "$@"

    uninstall
elif [ "$1" = "version" ]; then
    shift

    refuse_args "$#"

    print_setup_version
else
    exit_with_usage
fi
