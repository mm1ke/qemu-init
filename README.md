# qemu-init

qemu-init contains scripts for starting, stoping and manipulating qemu virtual machines. It includes 3 scripts and one example configuration file for virtual machines.
### kvm.init
kvm.init is a openrc init script usually used in gentoo. This can be used to create system services to start virtual machines via openrc.
### qvm
qvm is the qemu vm manager for stoping, starting, editing or simply listing virtual machines. It can be run as root and non-root users to play around with virtual machines.
### default.config
default.config shows an example configuration used for **kvm.init** and **qvm**. It also includes comments and sane default in order to quickly setup any virtual machine.

## Installation
In order to use these script simply copy **qvm** into `/usr/bin/`. If you're using the openrc init system and want to start vms as a service simply put **kvm.init** into `/etc/init.d/` and symlink vm configurations to it. configuration files need to be in `/etc/conf.d`.
For example:  
`cp kvm.init /etc/init.d/`  
`cp default.config /etc/conf.d/kvm.windows`  
`cd /etc/init.d/`  
`ln -s kvm.init kvm.windows`  

## License
All scripts are free software. You can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.
