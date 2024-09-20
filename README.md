# Setup.sh

Setup.sh is a POSIX compatible installer/uninstaller for shell scripts with development mode support.

Setup.sh has the following features:

- POSIX compatible and can run without Bash
- Minimal dependencies and suitable for embedded devices
- Minimal effort to make your shell scripts compatible with Setup.sh
- Provides a convenient way to implement development mode in your shell scripts
- Provides dry-run mode for installation and uninstallation

Setup.sh is not a full package manager. There are no centralized package lists and no package dependency management.

## Installation

Currently Setup.sh supports the following init systems:

- systemd
- sysvinit
- procd

You should find out which one your system is using and install Setup.sh with:

```shell
git clone https://github.com/williamthegrey/setup-sh.git
cd setup-sh
# Change "systemd" to your actual init system
sudo ./setup.sh install systemd
```

On some embedded systems, it is impossible to install anything to root dir "/". In this case, you can install Setup.sh to an allowed alternative root dir (like "/opt") with:

```shell
# Change "sysvinit" to your actual init system
# Change "/opt" to your actual root dir
sudo ./setup.sh install sysvinit --root-dir /opt
```

After that, Add this alternative root dir to your `PATH` variable.

## Configuration

One you have installed Setup.sh, you will have this "/etc/setup.conf" config file with content like:

```shell
# pkg dirs
pkg_init_dir=sysvinit

# sys dirs
sys_bin_dir=/usr/bin
sys_lib_dir=/usr/lib
sys_share_dir=/usr/share
sys_init_dir=/etc/init.d
sys_etc_dir=/etc
sys_var_dir=/var
```

Setup.sh is meant to install packages to your system. "sys dirs" are the installation destinations of the packages. While "pkg dirs" are the directories in your packages meant to be installed to system.

> [!NOTE]
> Setup.sh will not install any files from pkg_var_dir to sys_var_dir. Because var dirs are used to store run-time variable data, which does not belong to packages.

You can modify "sys dirs" and "pkg dirs" as needed. But among "pkg dirs", only pkg_init_dir can be modified, while the rest of "pkg dirs" is specified by Setup.sh internally.

> [!WARNING]
> Do not modify these configurations frequently. When Setup.sh uninstalls packages, it always uses currently configured "sys dirs". If a package was installed to old "sys dirs", and uninstalled from new "sys dirs", some files will not be deleted cleanly during uninstallation.

## Usage

Once you have a Setup.sh compatible package (here we use [sample-package](sample-package) shipped with Setup.sh as an example), you can install it with:

```shell
sudo setup install sample-package
```

"sample-package" here is the package directory. Of course, you can also enter the directory and install it like:

```shell
cd sample-package
sudo setup install .
```

If you are not confident about the configurations or anything, you can use dry-run mode. In dry-run mode, Setup.sh will print out the operations without actually installing the package. Then you can check if this is what you want before installing the package. Use dry-run mode with:

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

In order to use Setup.sh to install/uninstall your shell scripts, you should organize them as packages (just like the [sample-package](sample-package)).

### Package Structure

A Setup.sh package is a directory with predefined structures, which usually looks like this:

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

During installation of a package, Setup.sh will try to copy all contents inside of the subdirectories (aka the "pkg dirs" in setup.conf) to the corresponding directories in system (aka the "sys dirs" in setup.conf) if they exist in the package. So all of the subdirectories above are optional. And even package.sh is optional.

You may wonder why defining these subdirectories since all of them are meant be copied to system and it can be done with one single command. But no, you cannot. (Almost) every subdirectory is handled slightly differently during installation or uninstallation.

Here are the explanations of the subdirectories, alongside with package directory and package.sh:

- package directory: Used as the package name once installed to system by Setup.sh.
- bin: Contains entrance executable scripts, which will be made executable after installation.
- lib: Contains scripts or any kinds of libraries to be called by your executable scripts, which will be simply copied to system.
- share: Contains data and resources, which will be simply copied to system.
- etc: Contains config files, which will not overwrite existing files in system during installation, and will not be removed from system during uninstallation.
- systemd: Contains systemd init scripts, which will be enabled by `systemctl` command after installation.
- sysvinit: Contains sysvinit init scripts, which will be made executable and enabled by `update-rc.d` command after installation.
- procd: Contains procd init scripts, which will be made executable and enabled by the script itself with an `enable` argument after installation.
- package.sh: Contains optional info of the package and optional installation hooks, which will not be copied to system during installation.

### Add Config files

It is recommended to name your config files with a ".sample" extension, like "sample-package.conf.sample". Setup.sh will copy the config files to system with the ".sample" extension removed. And if you have any config files with almost the same names except without the ".sample" extension, like "sample-package.conf", Setup.sh will not copy them to system.

This mechanism has the following benefits:

- You will have two versions of config files, the non-sample version only stay in the package and can be used in development mode, while the sample version will be copied to system and used in production mode. In this way, the development environment and the production environment are separated.
- Since the ".sample" extension is removed when installing, the config files will have the same names in both development mode and production mode. In this way, you can easily refer your config files in your scripts. However, the paths of config files in development mode and production mode are different, which will be discussed later.

> [!TIP]
> Config files in development mode change frequently and depend on current system, so it is recommended to ignore them in your repository. But do not ignore the samples, which belong to the package and meant to be installed to system.

### Add Init scripts

Currently, Setup.sh supports three init systems. If you want to add init scripts to your package, you don't have to add all three types of init scripts. Just add the types which you want to support.

For example, If you only add init scripts in systemd directory and sysvinit directory in your package, then:

- On a system in which Setup.sh was installed with "systemd" argument (therefore setup.conf says `pkg_init_dir=systemd`), only systemd scripts in your package will be copied to that system.
- On a system in which Setup.sh was installed with "sysvinit" argument (therefore setup.conf says `pkg_init_dir=sysvinit`), only sysvinit scripts in your package will be copied to that system.
- On a system in which Setup.sh was installed with "procd" argument (therefore setup.conf says `pkg_init_dir=procd`), no init scripts in your package will be copied to that system.

This mechanism ensures every system will only be installed with compatible init scripts instead of useless ones.

### Add package.sh

Like package.json in Node.js, we use package.sh in Setup.sh to describe our package. But there is a significant difference them: package.sh is optional and all of its content are also optional, but package.json is not.

A package.sh usually looks like this:

```shell
VERSION="1.0.0"

pre_install() {
    echo "package.sh: Hello from pre_install"
}
```

Here are the explanations of the package.sh above:

- `VERSION`: Defines the version of this package, which can be printed with `setup list-installed` command once the package is installed. This variable is also available in your scripts both in development mode and production mode by sourcing `setup-env`, which will be discussed later.
- installation hooks: These are four installation hooks defined by Setup.sh: `pre_install`, `post_install`, `pre_uninstall` and `post_uninstall`. They will execute at the time indicated literally.

You can provide extra info for your package in package.sh by defining custom variables outside of hooks in package.sh just like defining `VERSION`. And these variables are available in your scripts by the same way as `VERSION`.

All output outside of hooks in package.sh is suppressed. Because package.sh will be sourced when executing `setup list-installed` command, which leads to malformatted output of this command if you have any output outside of hooks in package.sh. Therefore, Setup.sh has suppressed the output for you, in case you have to call external commands which might print a lot of stuff on screen.

> [!WARNING]
> Do not perform time-consuming operations outside of hooks in package.sh. Because package.sh will be sourced when executing `setup list-installed` command and whenever you source `setup-env`. Therefore, time-consuming operations result in slow `setup list-installed` command and slow scripts of your package.

### Use setup-env

`setup-env` is a script meant to be sourced in your scripts of your package, and it has the following capabilities:

- Provides you the current configs of Setup.sh, including all "pkg dirs" and "sys dirs".
- Provides you the `DEV` variable which indicates whether your script is executing in development mode or not.
- Provides you the "DIR" variables which indicate the location of your package files with development/production mode taken into account.
- Provides you the package info variables defined in package.sh, including `VERSION` (like we discussed before).

You can source it like this in POSIX:

```shell
# Change "sample-package" to your actual package name
pkg_name="sample-package"
. setup-env
```

or like this in Bash:

```shell
# Change "sample-package" to your actual package name
pkg_name="sample-package"
source setup-env
```

> [!TIP]
> You may remove the `pkg_name="sample-package"` line if you do not wish to access package info variables like `VERSION`.

Among many variables provided by `setup-env`, the `DEV` variable and the "DIR" variables are most important, and they are used to implement development mode in your scripts.

Here are the explanations of `DEV` variable:

- When you are developing the package, you can execute your entrance scripts in bin directory without installing the whole package.
- If you source `setup-env` in your scripts under the circumstance, Setup.sh will know that your scripts are executing outside of system bin directory (aka `sys_bin_dir` in setup.conf), so this script is considered to be executing in development mode, and the `DEV` variable is set to true.
- If you install the package and execute your entrance scripts inside of system bin directory (by using `/usr/bin/sample-package` or just `sample-package`), with `setup-env` sourced in your scripts, Setup.sh will find out that your scripts are executing inside of system bin directory, so this script is considered to be executing in production mode, and the `DEV` variable is set to false.

You can adapt your logic according to the value of `DEV` variable. But in most cases, in order to separate development mode and production mode, you only need to distinguish the paths of your package files in two modes, and logic can remain unchanged. You can use "DIR" variables to accomplish that, and here are the explanations:

- In development mode, all package files you want to access stay in the package, so the "DIR" variables are set to point to the "pkg dirs" (like `ETC_DIR=/home/user/Workspace/setup-sh/sample-package/etc`) for you.
- In production mode, all package files you want to access stay in system, so the "DIR" variables are set to point to the "sys dirs" (like `ETC_DIR=/etc`) for you.

So instead of referring your package files hard coded (like `/etc/sample-package.conf`), you can refer them using "DIR" variables (like `$ETC_DIR/sample-package.conf`) to easily implement development mode separated from production mode. And like we discussed before, the config file names stay the same in both modes, therefore the paths like `$ETC_DIR/sample-package.conf` are always valid, which simplifies your work.

## Uninstallation

In order to uninstall Setup.sh, you should uninstall all of the packages first. Because packages might be using `setup-env` and variables provided by it, and if you uninstall Setup.sh, `setup-env` will become unavailable, and those packages will not work properly for certain. Since we can not know which packages are using `setup-env`, so it is not allowed to uninstall Setup.sh before uninstalling all of the packages, and `setup.sh` script will complain if you try.

After uninstalling all of the packages, uninstall Setup.sh with:

```shell
cd setup-sh
sudo ./setup.sh uninstall
```

If you have installed Setup.sh to an alternative root dir previously, you should uninstall it with:

```shell
# Change "/opt" to your actual root dir
sudo ./setup.sh uninstall --root-dir /opt
```
