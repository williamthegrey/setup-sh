#!/bin/sh

VERSION="1.0.0"
CUSTOM_INFO="CUSTOM_INFO_VALUE"

echo "package.sh: Output outside of hooks (like this one) will be suppressed"

post_install() {
    echo "package.sh: Hello from post_install"
}

pre_uninstall() {
    echo "package.sh: Hello from pre_uninstall"
}
