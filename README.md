# qemu-init

qemu-init contains scripts for starting, stoping and manipulating qemu virtual machines and includes init scripts for `openrc`.
### kvm.init
kvm.init is a openrc init script usually used in gentoo. This can be used to create system services to start virtual machines via openrc.
### kvm
kvm.confd is the default configuration file for the `kvm.init` script.
### qvm
qvm is the qemu vm manager for stopping, starting, editing or simply listing virtual machines. It can be run as root and non-root users to play around with virtual machines
```code
qvm
start/stop and manipulating qemu vms

guest start/stopping
qvm b|s|r|x|f|l|c|p vmname|/path/to/configfile
 b|boot					boot virtual machine config file
 s|stop					stop virtual machine
 r|reboot				restart virtual machine (via qemu guest agent)
 x|reset				reset virtual machine
 f|freeze				freeze|unfreeze guest filesystem (via qemu guest agent)
 l|list					list all virtual machines|show details of [vmname]
 c|connect				connect to the unix socket of [vmname]
 p|pause				pause/unpause qemu virtualization

vm/guest modify
qvm update vmname memory|sendkey|[spice|vnc] value
 memory 4096			change the memory of [vmname] via ballooing
 sendkey ctrl-alt-f1	send key combination to [vmname] (like ctrl-alt-f1)
 vnc|spice P4ssw0rd		change vnc or spice password of [vmname]

vm/guest snapshoting
qvm snapshot vmname create|delete|info|load [value]
 create [value]			create a new snapshot called [value(optional)]
 delete [value]			delete snapshot [value]
 snapshot list			list available snapshots
 load [value]			load snapshot [value]

host network
qvm network add|del tap-name,[bridge-dev(br0)]
 add					create a new tap device and link it to [bridge-dev]
 del					remove a tap device
```
### default.config
default.config shows an example configuration used for **kvm.init** and **qvm**. It also includes comments and sane defaults in order to quickly setup any virtual machine.
### qvm-completion.bash
this file contains a completion script for qvm.

## Installation
In order to use these script simply copy **qvm** into `/usr/bin/`. If you're using the openrc init system and want to start vms as a service simply put **kvm.init** into `/etc/init.d/` and symlink vms to it. configuration files need to be installed in `CONF_PATH` (default is /etc/qvm/), or can be set in `/etc/conf.d/kvm`.
For example:  
`cp kvm.init /etc/init.d/`  
`cp kvm.confd /etc/conf.d/kvm`  
`cp qvm /usr/bin/`  
`chmod +x /usr/bin/qvm`  
`cp default.config /etc/qvm/kvm.windows`  
`cd /etc/init.d/`  
`ln -s kvm.init kvm.windows`  

## License
All scripts are free software. You can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.
