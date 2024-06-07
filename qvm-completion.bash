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
	local _qvm_comp_cmd_all _qvm_comp_cmd_update _qvm_comp_cmd_snapshot _qvm_comp_cmd_parameters
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
	[ -e ~/.config/qvm/qvm.conf ] && source ~/.config/qvm/qvm.conf

	local _qvm_comp_cmd_update="
memory       change vm memory
sendkey      send key combinatin to vm
vnc          change vnc password
spice        change spice password"

	local _qvm_comp_cmd_snapshot="
create       create a new snapshot
delete       delete existing snapshot
list         list available snapshots
load         load a specifig snapshot"

	local _qvm_comp_cmd_hw="
add          add a new PCI device
remove       remove a PCI device
list         list PCI devices added"

	local _qvm_comp_cmd_all="
boot         boot virtual machine
kill         kill virtual machine instantly
stop         shutdown virtual machine
reboot       reboot virtual machine (via qemu guest agent)
reset        resets virtual machine
freeze       freezes/thaws virtual machine (via qemu guest agent)
pause        pause/unpause guest emulation
list         list all running/stopped virtual machines
connect      connect to a virtual machine socket
update       updates certain virtual machine settings
network      add/removes tap interfaces on the host
snapshot     create/delete/load/list available snapshots
hw           add/remove/list pci devices"

 local _qvm_comp_cmd_parameters="
readonly     start the vm in snapshot mode (changes wont be saved)
pxeboot      start the vm and force booting from network
fullscreen   start the vm in fullscreen mode
nodisplay    start the vm without display output
dryrun       dryrun: don't boot the vm but print out the startparameters"

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
						local _vms="$(find ${CFG_DIR} -type f -printf '%f\n'|sort)"
						__qvm_comp_with_text "$(find ${CFG_DIR} -type f -printf '%f\n'|sort)"
					else

						__qvm_comp_with_text "$(find /etc/init.d/kvm.* -type l -printf '%f\n'|cut -d'.' -f2-|sort)"
					fi
					;;
				stop|s|reboot|r|reset|x|freeze|f|list|l|connect|c|update|u|snapshot|e|pause|p|hw|h|kill|k)
					COMPREPLY=($(compgen -W "$(find ${pid_dir} -name *.qvm.pid -printf '%f\n'|rev|cut -d'.' -f3-|rev)" -- ${cur}))
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
				boot|b)
					__qvm_comp_with_text "${_qvm_comp_cmd_parameters}"
					;;
				update|u)
					__qvm_comp_with_text "${_qvm_comp_cmd_update}"
					;;
				snapshot|e)
					__qvm_comp_with_text "${_qvm_comp_cmd_snapshot}"
					;;
				hw|h)
					__qvm_comp_with_text "${_qvm_comp_cmd_hw}"
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
				delete)
					local snapshots="$(echo "info snapshots" \
						| nc -U -q1 /run/user/$(id -u)/${COMP_WORDS[COMP_CWORD-2]}.sock \
						| tail -n+5 \
						| head -n-1 \
						| tr -s \ '' \
						| cut -d' ' -f2\
						| tr '\n' ' ')"
						COMPREPLY=($(compgen -W "$(echo "${snapshots}")" -- ${cur}))
					;;
				load)
					local snapshots="$(echo "info snapshots" | nc -U -q1 /run/user/$(id -u)/${COMP_WORDS[COMP_CWORD-2]}.sock)"
					COMPREPLY=($(compgen -W "$(echo "${snapshots}"|tail -n+5|head -n-1|tr -s \ '' | cut -d' ' -f2|tr '\n' ' ')" -- ${cur}))
					;;
				add)
					COMPREPLY=($(compgen -W "harddisk network" -- ${cur}))
					;;
				remove)
					local devices="$(
						for x in $(cat /run/user/$(id -u)/${COMP_WORDS[COMP_CWORD-2]}.pcie.map \
						| tr '|' '\n' \
						| head -n -1 \
						| nl -w1 -s'-' -b a);
							# check if the second part of the string is empty (there is always a first part because of nl)
							do if [ -n "$(echo $x| cut -d'-' -f2)" ]; then
								echo $x;
							fi;
						done | tr '\n' ' '
						)"
					COMPREPLY=($(compgen -W "$(echo "${devices}")" -- ${cur}))
					;;
			esac
			;;
		5)
			case ${prev} in
				network)
					COMPREPLY=($(compgen -W "$(grep -v -e '^$' -e '^#' /etc/qemu/bridge.conf | cut -d' ' -f2|sort -u)" -- ${cur}))
					;;
				harddisk)
					if [ -n "${IMG_DIR}" ]; then
						#local _vms="$(find ${CFG_DIR} -type f -printf '%f\n'|sort)"
						__qvm_comp_with_text "$(find ${IMG_DIR} -type f -printf '%f\n'|sort)"
					fi
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
