#!/bin/sh

install() {
    init_sys_dirs

    # Check package in system
    if [ -d "$sys_setup_sh_dir" ]; then
        echo "Setup.sh has already been installed and will be uninstalled first"
        uninstall --force
    fi

    echo "Install: started"

    # Copy setup-sh to system
    mkdir -p "$sys_setup_sh_dir"
    cp -r * "$sys_setup_sh_dir"

    pre_install

    copy_files "$pkg_bin_dir" "$sys_bin_dir"
    copy_files "$pkg_lib_dir" "$sys_lib_dir"
    copy_files "$pkg_share_dir" "$sys_share_dir"
    copy_files "$pkg_init_dir" "$sys_init_dir"
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
    elif [ "$init_system" = "launchd" ]; then
        sys_init_dir="/Library/LaunchDaemons"
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

    sed $(get_replace_options "$@") "template/$template_file" >"$template_file"
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

    # Check setup-sh in system
    if [ ! -d "$sys_setup_sh_dir" ]; then
        echo "Error: Setup.sh has not been installed"
        exit 1
    fi

    # Check packages in system
    if [ "$1" != "--force" ] && [ -d "$sys_pkgs_dir" ]; then
        local packages=$(ls -1 "$sys_pkgs_dir")
        if [ ! -z "$packages" ]; then
            echo "Error: Cannot uninstall Setup.sh before uninstalling all of the packages."
            exit 1
        fi
    fi

    echo "Uninstall: started"

    cd "$sys_setup_sh_dir"

    remove_files "$pkg_bin_dir" "$sys_bin_dir"
    remove_files "$pkg_lib_dir" "$sys_lib_dir"
    remove_files "$pkg_share_dir" "$sys_share_dir"
    remove_files "$pkg_init_dir" "$sys_init_dir"
    # Avoid removing $sys_etc_dir/setup.conf and preserve relative administration efforts

    cd - >/dev/null

    # Delete setup-sh from system
    rm -rf "$sys_setup_sh_dir"

    echo "Uninstall: finished"
}

exec="./setup.sh"

help() {
    echo "$exec $setup_version"
    usage
}

usage() {
    printf "Usage:\n"
    printf "\t$exec install <init_system> [--root-dir <dir>]\n"
    printf "\t$exec uninstall [--root-dir <dir>]\n"
    printf "\t$exec version\n"
    printf "\t$exec help\n"
    printf "Arguments:\n"
    printf "\tinit_system\tThe value can be: systemd|sysvinit|procd|launchd\n"
    printf "Options:\n"
    printf "\t--root-dir\tThe root dir of installation destionation\n"
}

init_sys_dirs() {
    sys_bin_dir="$sys_root_dir/usr/local/bin"
    sys_lib_dir="$sys_root_dir/usr/local/lib"
    sys_share_dir="$sys_root_dir/usr/local/share"
    sys_etc_dir="$sys_root_dir/etc"

    sys_pkgs_dir="$sys_root_dir/usr/local/lib/setup/packages"
    sys_setup_sh_dir="$sys_root_dir/usr/local/lib/setup/setup-sh"
}

parse_root_dir_arg() {
    if [ "$#" -gt 0 ]; then
        if [ "$1" = "--root-dir" ]; then
            shift

            require_args "$#" 1
            sys_root_dir="$1"
            shift

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
    if [ "$1" = "systemd" ] || [ "$1" = "sysvinit" ] || [ "$1" = "procd" ] || [ "$1" = "launchd" ]; then
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
elif [ "$1" = "help" ]; then
    shift

    refuse_args "$#"

    help
else
    exit_with_usage
fi
