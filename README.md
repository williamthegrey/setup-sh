# Setup.sh

Setup.sh is a POSIX compatible installer/uninstaller for shell scripts with dev mode support.

Setup.sh has the following features:

- POSIX compatible and can run without Bash
- Minimal dependencies and suitable for embedded devices
- Minimal effort to make your shell scripts compatible with Setup.sh
- Provides a convenient way to implement dev mode in your shell scripts
- Provides dry-run mode for installation and uninstallation

Setup.sh is not a full package manager. There are no centralized package lists and no package dependencies.

## Installation

Currently Setup.sh supports the following init systems:

- systemd
- sysvinit

You should find out which one your system is using and install Setup.sh with (suppose your init system is sysvinit):

```shell
git clone https://github.com/williamthegrey/setup-sh.git
cd setup-sh
sudo ./setup.sh install sysvinit # Change sysvinit to your actual init system
```

## Configuration

One you have installed Setup.sh, you will have this "/etc/setup.conf" config file with the content like:

```shell
# pkg dirs
pkg_init_dir=sysvinit

# sys dirs
sys_bin_dir=/usr/bin
sys_lib_dir=/usr/lib
sys_share_dir=/usr/share
sys_init_dir=/etc/init.d
sys_etc_dir=/etc
```

You can modify "sys dirs" to adjust the installation destinations of the packages which are about to be installed by Setup.sh. And you can modify "pkg dirs" to let Setup.sh know which directories in your packages are meant to be installed to system. But only modifying pkg_init_dir is recommended, while the rest of "pkg dirs" should be decided by Setup.sh for the consistency across all packages.

Warning: Do not modify these configurations frequently. When Setup.sh uninstalls packages, it always uses currently configured "sys dirs". If a package was installed to old "sys dirs", some files will not be deleted cleanly during uninstallation.

## Usage

Once you have a Setup.sh compatible package, you can install it with (suppose it is stored in the directory named "package"):

```shell
sudo setup install package
```

If you are not confident about the configurations or anything, you can use dry-run mode. In dry-run mode, Setup.sh will print out the operations without actually installing the package. Then you can checkout if this is what you want before installing the package. Use dry-run mode with:

```shell
sudo setup install package --dry-run
```

You can list all packages installed by Setup.sh with:

```shell
setup list-installed
```

You can uninstall the package with:

```shell
sudo setup uninstall package
```

Of course, you can use dry-run mode before actually uninstalling with:

```shell
sudo setup uninstall package --dry-run
```
