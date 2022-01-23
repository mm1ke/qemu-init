#/usr/bin/env #!/bin/bash

# Filename: qvm-completion.bash
# Autor: Michael Mair-Keimberger (mmk AT levelnine DOT at)
# Date: 23.01.2022

# Copyright (C) 2022  Michael Mair-Keimberger
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

# Discription:
# qvm-completion: bash completion for qvm

PID_DIR="/run/kvm"
if ! [ $(id -u) = 0 ]; then
	PID_DIR="/run/user/$(id -u)"
fi
source ~/.qvm.conf

COMP_CMD_UPDATE="
memory       change vm memory
sendkey      send key combinatin to vm
vnc          change vnc password
spice        change spice password
"

COMP_CMD_ALL="
boot         boot virtual machine
stop         shutdown virtual machine
reboot       reboot virtual machine (via qemu guest agent)
reset        resets virtual machine
freeze       freezes/thaws virtual machine (via qemu guest agent)
list         list all running/stopped virtual machines
connect      connect to a virtual machine socket
update       updates certain virtual machine settings
network      add/removes tap interfaces on the host
"

function comp_with_text(){
	local OLDIFS="${IFS}"
	local IFS=$'\n'
	local completions=($(compgen -W "${1}" -- ${cur}))

	if [[ ${#completions[*]} -eq 1 ]]; then
		COMPREPLY=( ${completions[0]%% *} )
	else
		for i in "${!completions[@]}"; do
			completions[$i]="$(printf '%*s' "-$COLUMNS" "${completions[$i]}")"
		done
		COMPREPLY=("${completions[@]}")
	fi
	IFS="${OLDIFS}"
}


function _list(){
	local cur prev
	COMPREPLY=()
	cur=${COMP_WORDS[COMP_CWORD]}
	prev=${COMP_WORDS[COMP_CWORD-1]}

	case ${COMP_CWORD} in
		1)

			comp_with_text "${COMP_CMD_ALL}"
			;;
		2)
			case ${prev} in
				boot|b)
					COMPREPLY=($(compgen -W "$(find ${CFG_DIR} -type f -printf '%f\n'|sort)" -- ${cur}))
					;;
				stop|s|reboot|r|reset|x|freeze|f|list|l|connect|c|update|u)
					COMPREPLY=($(compgen -W "$(find ${PID_DIR} -name *.pid -printf '%f\n'|rev|cut -d'.' -f2-|rev)" -- ${cur}))
					;;
				network|n)
					COMPREPLY=($(compgen -W "add del" -- ${cur}))
					;;
			esac
			;;
		3)
			case ${prev} in
				add)
					COMPREPLY=($(compgen -W "qtap0 qtap1 qtap2 qtap3" -- ${cur}))
					;;
				del)
					COMPREPLY=($(compgen -W "$(find /sys/class/net/*/tun_flags | cut -d'/' -f5)" -- ${cur}))
					;;
			esac
			case ${COMP_WORDS[COMP_CWORD-2]} in
				update|u)
					comp_with_text "${COMP_CMD_UPDATE}"
					;;
			esac
			;;
		4)
			case ${prev} in
				mem|memory)
					COMPREPLY=($(compgen -W "1024 2048 4096 8192 16284 32768" -- ${cur}))
					;;
				key|sendkey)
					COMPREPLY=($(compgen -W "ctrl-alt-f1 ctrl-alt-f7 ctrl-alt-delete" -- ${cur}))
					;;
			esac
			;;
		*)
			COMPREPLY=()
			;;
	esac
}

complete -F _list qvm
