# qemu-init

This repository contains scripts for starting, stopping and manipulation `qemu` virtual machines.  

### Motivation
Initially i've wrote this script in order to have a `openrc` init script to start and stop virtual machines without the the need to depend on `app-emulation/libvirt`. However, as I started to play more with virtual machines directly (and not as an system service), i've decided to create `qvm` which is a simple tool to work with virtual machines directly.  
The init script still require `qvm` to be present for starting and stopping vm's as a service, but `qvm` can be used as a standalone tool perfectly well.

## qvm (qemu vm manager)
This is a bash script for managing qemu virtual machines. Features include:
- start / stop / reset / freeze qemu virtual machines
- modify guests
	- set vnc/spice password
	- change memory (ballooning)
	- send key strokes
- modify guests hardware
	- add / remove pcie devices (network adapters and/or hard-disks)
	- list connected pcie devices
- guest snapshoting
	- create / remove snapshots
	- list available snapshots
	- load snapshots as needed
- host network
	- add / remove tap interfaces on the host

### Dependencies
`qvm` require to have following tools installed:
- app-emulation/qemu
- net-misc/bridge-utils
- net-analyzer/openbsd-netcat or net-misc/socat
- sys-apps/iproute2

### qvm-completion.bash
`qvm` comes with a nice bash completion too.

## kvm.init & kvm.confd
`kvm.init` is the `openrc` init script. This can be used to create system services to start virtual machines via `openrc`. `kvm.init` requires `qvm` in order to start and stop virtual machines.  
`kvm.confd` is the default configuration file for the `kvm.init` script.  

### default.config
There is also a `default.config` included which can be used as an example configuration for new virtual machines. Configuration files are usually put into `/etc/qvm/`. However the path can be changed (see below).


## Installation

### qvm
In order to use **qvm**, simply put it into `/usr/bin/`. The completion should be put into `/usr/share/bash-completionk/completions/` (on a gentoo box).
**qvm** first checks if there is a `~/.config/qvm/qvm.conf` which it would source if available. In this file you can set the default configuration path for virtual machines, as well as other settings:

``` sh
cp qvm /usr/bin/
chmod +x /usr/bin/qvm
```

Create a new configuration file:
``` sh
touch ~/.config/qvm/qvm.conf
```

- `CFG_DIR="~/vmcfg"` set's the default path for vm configuration files
- `VM_KILL_WAIT="20"` set's the default time to wait until a vm should be killed (after initiating a shutdown)
- `TAP_DELETE=false` defines if created TAP devices should be removed from the host when a vm shut down.

**qvm** usually doesn't need any root privileges. However this also depends on the VM config. For example, TAP devices require root privileges to be created, which `qvm` kindly would ask for.  
The `default.config` work with bridge devices, which itself are TAP devices again but are handled by `qemu` directly. Here it's once required to allow `qemu` for which bridge devices it can create tap devices for. This can be configured in `/etc/qemu/bridge.conf`. After that users can create/delete TAP devices without root privileges.

If **qvm** is run as `root` user it also looks for an configuration in the root's home directory. In the absence of the configuration file it tries to use the default config directory under `/etc/qvm` - were config files of service vm's should be put to.

### init scripts
If you're using the openrc init system and want to start vms as a service simply put **kvm.init** into `/etc/init.d/` and symlink vms to it. configuration files need to be installed in `CONF_PATH` (default is /etc/qvm/), or can be set in `/etc/conf.d/kvm`.
For example:  
``` sh
cp kvm.init /etc/init.d/
cp kvm.confd /etc/conf.d/kvm
```
Note that `qvm` is required to be installed.

To add a new vm as a service:
``` sh
cp default.config /etc/qvm/kvm.gentoo
cd /etc/init.d/
ln -s kvm.init kvm.gentoo
```
## License
All scripts are free software. You can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.
