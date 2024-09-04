# Setup.sh

Setup.sh is a POSIX compatible installer/uninstaller for shell scripts with development mode support.

Setup.sh has the following features:

- POSIX compatible and can run without Bash
- Minimal dependencies and suitable for embedded devices
- Minimal effort to make your shell scripts compatible with Setup.sh
- Provides a convenient way to implement development mode in your shell scripts
- Provides dry-run mode for installation and uninstallation

Setup.sh is not a full package manager. There are no centralized package lists and no package dependencies.

## Installation

Currently Setup.sh supports the following init systems:

- systemd
- sysvinit
- procd

You should find out which one your system is using and install Setup.sh with (suppose your init system is systemd):

```shell
git clone https://github.com/williamthegrey/setup-sh.git
cd setup-sh
sudo ./setup.sh install systemd # Change "systemd" to your actual init system
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

You can modify "sys dirs" to adjust the installation destinations of the packages which are about to be installed by Setup.sh. And you can modify "pkg dirs" to let Setup.sh know which directories in your packages are meant to be installed to system. But only modifying pkg_init_dir is allowed, while the rest of "pkg dirs" is specified by Setup.sh internally.

Warning: Do not modify these configurations frequently. When Setup.sh uninstalls packages, it always uses currently configured "sys dirs". If a package was installed to old "sys dirs", some files will not be deleted cleanly during uninstallation.

## Usage

Once you have a Setup.sh compatible package, you can install it with (here we use "sample-package" shipped with Setup.sh as an example):

```shell
sudo setup install sample-package
```

"sample-package" here is the package directory. Of course, you can also enter the directory and install it with:

```shell
cd sample-package
sudo setup install .
```

If you are not confident about the configurations or anything, you can use dry-run mode. In dry-run mode, Setup.sh will print out the operations without actually installing the package. Then you can checkout if this is what you want before installing the package. Use dry-run mode with:

```shell
sudo setup install sample-package --dry-run
```

You can list all packages installed by Setup.sh with:

```shell
sudo setup list-installed
```

You can uninstall the package with:

```shell
sudo setup uninstall sample-package
```

Of course, you can use dry-run mode before actually uninstalling with:

```shell
sudo setup uninstall sample-package --dry-run
```

## Create a Package

In order to use Setup.sh to install/uninstall your shell scripts, you should organize them as packages (just like the "sample-package").

### Package Structure

A Setup.sh package is a directory with predefined structures, is usually looks like this:

```text
sample-package/
├── bin/
├── lib/
├── share/
├── etc/
├── systemd/
├── sysvinit/
├── procd/
└── package.sh
```

During installation of the package, Setup.sh will try to copy all contents inside of the subdirectories (aka the "pkg dirs" in setup.conf) to the corresponding directories in system (aka the "sys dirs" in setup.conf) if they exist in the package. So all of the subdirectories above are optional. And even package.sh is optional.

You may wonder why defining these subdirectories since all of them are meant be copied to system and it can be done with one single command. But no, you cannot. (Almost) every subdirectory is handled slightly differently during installation/uninstallation.

Here are the explains of the subdirectories, alongside with package directory and package.sh:

- package directory: Used as the package name once installed to system by Setup.sh.
- bin: Contains entrance executable scripts, which will be made executable after installation.
- lib: Contains scripts or any kinds of libraries to be called by your executable scripts, which will be simply copied to system.
- share: Contains data and resources, which will be simply copied to system.
- etc: Contains config files, which will not overwrite existing files in system during installation, and will not be removed from system during uninstallation.
- systemd: Contains systemd init scripts, which will be enabled by `systemctl` command after installation.
- sysvinit: Contains sysvinit init scripts, which will be made executable and enabled by `update-rc.d` command after installation.
- procd: Contains procd init scripts, which will be made executable and enabled by the script itself with an `enable` argument after installation.
- package.sh: Contains optional info of the package and optional installation hooks, which will not be copied to system during installation.

### Config files

It is recommended to name your config files with a ".sample" extension, like "sample-package.conf.sample". Setup.sh will copy the config files to system with the ".sample" extension removed. And if you have any config files with almost the same names except without the ".sample" extension, like "sample-package.conf", Setup.sh will not copy them to system.

This mechanism has the following benefits:

- You will have two versions of config files, the non-sample version only stay in the package and can be used in development mode, while the sample version will be copied to system and used in production mode. In this way, the development environment and the production environment are separated.
- Since the ".sample" extension is removed when installing, the config files will have the same names (the non-sample version) in both development mode and production mode. In this way, you can easily refer your config files in your scripts. However, the paths in development mode and production mode are different, which will be discussed later.

### Init scripts

Currently, Setup.sh supports 3 kinds of init systems. If you want to add init scripts to your package, you don't have to add all 3 kinds of init scripts. Just add the init scripts for the init systems which you want to support.

For example, If you only add init scripts in systemd directory and sysvinit directory in your package, then:

- On a system in which Setup.sh was installed with "systemd" argument (therefore setup.conf says "pkg_init_dir=systemd"), only systemd scripts in your package will be copied to that system.
- On a system in which Setup.sh was installed with "sysvinit" argument (therefore setup.conf says "pkg_init_dir=sysvinit"), only sysvinit scripts in your package will be copied to that system.
- On a system in which Setup.sh was installed with "procd" argument (therefore setup.conf says "pkg_init_dir=procd"), no init scripts in your package will be copied to that system.

This mechanism ensures every system will only be installed with compatible init scripts instead of useless ones.

### package.sh

### Development mode

## Uninstallation

In order to uninstall Setup.sh, you should uninstall all of the packages first. Because packages might be using setup-env to implement development mode, and if you uninstall Setup.sh, setup-env will become unavailable, and those packages will not work properly. Since we do not know which packages are using setup-env, So it is unrecommended to uninstall Setup.sh before uninstalling all of the packages. And this uninstallation operation has been prohibited in "setup.sh" script.

After uninstalling all of the packages, uninstall Setup.sh with:

```shell
cd setup-sh
sudo ./setup.sh uninstall
```
