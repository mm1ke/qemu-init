#!/sbin/runscript

# Filename: kvm.init
# Autor: Michael Mair-Keimberger (m DOT mairkeimberger AT gmail DOT com)
# Date: 13.08.2009

# Copyright (C) 2015  Michael Mair-Keimberger
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
# start/stop script for qemu guests


#
# info()
# get information about running vms
#
info(){
	# there are two possibilities how to run this command:
	# first: calling kvm.init with the vm-name (/etc/init.d/kvm.winxp info)
	#	which would show information only about the vm "winxp"
	# secondly: calling kvm.init directly (/etc/init.d/kvm.init info)
	#	calling kvm.init directly, the script should output
	#	(if possibly in a nice form) information about ALL running vm's.

	if [ "$VM_NAME" = "init" ]; then
		einfo "VM Overview"
		local r_vm

		for r_vm in ${PID_DIR}/*.pid; do
			if [ -e ${r_vm} ]; then
				local pid="`cat ${r_vm}`"
				local uptime="`ps -o "etime=" ${pid}`"
				local starttime="`ps -o "lstart=" ${pid}`"
				VM_NAME="`echo ${r_vm}|sed "s|"${PID_DIR}/"||g"`"
				VM_NAME=${VM_NAME%.pid}

				if ( `ps -p ${pid} -f --no-heading | grep "spice" > /dev/null 2>&1` ); then
					local VM_REMOTE_ACCESS="spice"
					local address_port="`echo "info spice" \
						| ${NC} --unix -q1 ${PID_DIR}/${VM_NAME}.sock 2>&1 \
						| grep --only-matching --perl-regex "(?<=address\:).*[0-9]" \
						| head -n1`"
				elif ( `ps -p ${pid} -f --no-heading | grep "vnc" > /dev/null 2>&1` ); then
					local VM_REMOTE_ACCESS="vnc"
					local address_port="`echo "info vnc" \
						| ${NC} --unix -q1 ${PID_DIR}/${VM_NAME}.sock 2>&1 \
						| grep --only-matching --perl-regex "(?<=address\:).*[0-9]" \
						| head -n1`"
				else
					local VM_REMOTE_ACCESS="NONE"
					local address_port="NONE"
				fi

				local qtap_dev="`echo "info network" \
					| ${NC} --unix -q1 ${PID_DIR}/${VM_NAME}.sock 2>&1 \
					| grep --only-matching --perl-regex "(?<=ifname\=).*[0-9]"`"
				
				local mac_addr="`echo "info network" \
					| ${NC} --unix -q1 ${PID_DIR}/${VM_NAME}.sock 2>&1 \
					| grep --only-matching --perl-regex "(?<=macaddr\=).*[a-fA-F0-9]"`"

				[ -z ${qtap_dev} ] && qtap_dev="NONE"
				[ -z ${mac_addr} ] && mac_addr="NONE"

				if ( `ps -p ${pid} -f --no-heading | grep "snapshot" > /dev/null 2>&1` ); then
					local snapshot="yes"
				else
					local snapshot="no"
				fi

				einfo " * ${VM_NAME} (PID:${pid})"
				einfo "   Snapshotmode: ${snapshot}"
				einfo "   Uptime: ${uptime} (started @ ${starttime})"
				einfo "   Network: ${VM_REMOTE_ACCESS} @${address_port} (${mac_addr}) on ${qtap_dev}"
				echo

			fi
		done
	else
		# default settings
		local address_port="NONE"
		local qtap="NONE"

		# get the information
		if [ -e ${PID_DIR}/${VM_NAME}.pid ]; then
			local pid="`cat ${PID_DIR}/${VM_NAME}.pid`"
			local uptime="`ps -o "etime=" ${pid}`"
			local starttime="`ps -o "lstart=" ${pid}`"
			if ( ${VM_ENABLE_REOMTE_ACCESS} ); then
				if [ "${VM_REMOTE_ACCESS}" = "spice" ]; then
					local address_port="`echo "info spice" \
						| ${NC} --unix -q1 ${PID_DIR}/${VM_NAME}.sock 2>&1 \
						| grep --only-matching --perl-regex "(?<=address\:).*[0-9]" \
						| head -n1`"
				elif [ "${VM_REMOTE_ACCESS}" = "vnc" ]; then
					local address_port="`echo "info vnc" \
						| ${NC} --unix -q1 ${PID_DIR}/${VM_NAME}.sock 2>&1 \
						| grep --only-matching --perl-regex "(?<=address\:).*[0-9]" \
						| head -n1`"
				else
					ewarn "${VM_REMOTE_ACCESS} not valid"
				fi
			fi

			if ! [ "${VM_NET_TYP}" = "none" ]; then
				if [ "${VM_NET_TYP}" = "tap" ]; then
					local qtap_dev="`echo "info network" \
						| ${NC} --unix -q1 ${PID_DIR}/${VM_NAME}.sock 2>&1 \
						| grep --only-matching --perl-regex "(?<=ifname\=).*[0-9]"`"
				fi
				if [ -z "${VM_MAC_ADDRESS}" ]; then
					local mac_addr="`echo "info network" \
						| ${NC} --unix -q1 ${PID_DIR}/${VM_NAME}.sock 2>&1 \
						| grep --only-matching --perl-regex "(?<=macaddr\=).*[a-fA-F0-9]"`"
				else
					local mac_addr="${VM_MAC_ADDRESS}"
				fi
			fi
		fi

		einfo "Information about: ${VM_NAME}"
		if ( ${VM_ENABLE_SNAPSHOTMODE} ); then
			einfo " ** VM is running in SNAPSHOT mode! **"
		fi
		echo
		einfo " VM started at: ${starttime}"
		einfo " Uptime: ${uptime}"
		einfo " PID: ${pid}"
		echo
		einfo " Remote Access via: ${VM_REMOTE_ACCESS}"
		einfo " Ip/Port: ${address_port}"
		echo
		einfo " Network Typ: ${VM_NET_TYP}"
		einfo " qdap-device: ${qtap_dev}"
		einfo " MAC-Address: ${mac_addr}"
	fi
}

