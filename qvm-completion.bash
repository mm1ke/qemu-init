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

function _qvm_comp_list(){

	local _qvm_comp_cmd_all _qvm_comp_cmd_update
	local cur prev pid_dir

	function __qvm_comp_with_text(){
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

	if [ ${#COMP_WORDS[@]} -lt 2 ]; then
		return
	fi

	local pid_dir="/run/kvm"
	if ! [ $(id -u) = 0 ]; then
		local pid_dir="/run/user/$(id -u)"
	fi
	[ -e ~/.qvm.conf ] && source ~/.qvm.conf

	local _qvm_comp_cmd_update="
memory       change vm memory
sendkey      send key combinatin to vm
vnc          change vnc password
spice        change spice password"

	local _qvm_comp_cmd_all="
boot         boot virtual machine
stop         shutdown virtual machine
reboot       reboot virtual machine (via qemu guest agent)
reset        resets virtual machine
freeze       freezes/thaws virtual machine (via qemu guest agent)
list         list all running/stopped virtual machines
connect      connect to a virtual machine socket
update       updates certain virtual machine settings
network      add/removes tap interfaces on the host"

	COMPREPLY=()
	local cur=${COMP_WORDS[COMP_CWORD]}
	local prev=${COMP_WORDS[COMP_CWORD-1]}

	case ${COMP_CWORD} in
		1)
			__qvm_comp_with_text "${_qvm_comp_cmd_all}"
			;;
		2)
			case ${prev} in
				boot|b)
					if [ -n "${CFG_DIR}" ]; then
						COMPREPLY=($(compgen -W "$(find ${CFG_DIR} -type f -printf '%f\n'|sort)" -- ${cur}))
					else
						COMPREPLY=($(compgen -W "$(find /etc/init.d/kvm.* -type l -printf '%f\n'|cut -d'.' -f2-|sort)" -- ${cur}))
					fi
					;;
				stop|s|reboot|r|reset|x|freeze|f|list|l|connect|c|update|u)
					COMPREPLY=($(compgen -W "$(find ${pid_dir} -name *.pid -printf '%f\n'|rev|cut -d'.' -f2-|rev)" -- ${cur}))
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
					__qvm_comp_with_text "${_qvm_comp_cmd_update}"
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
	return 0
}

complete -F _qvm_comp_list qvm
