#!/bin/bash

# Filename: vminfo.sh
# Autor: Michael Mair-Keimberger (m DOT mairkeimberger AT gmail DOT com)
# Date: 14.12.2015

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
# split from kvm.init
# vminfo.sh shows statistics from vms

BRCTL="/sbin/brctl" # net-misc/bridge-utils
IP="/bin/ip" # sys-apps/iproute2
NC="/usr/bin/nc" # net-analyzer/netcat6

PID_DIR="/var/run/kvm"
TMP_DIR="/var/tmp"

#
# info()
# get information about running vms

#
# there are two possibilities how to run this command:
# first: calling kvm.init with the vm-name (/etc/init.d/kvm.winxp info)
#	which would show information only about the vm "winxp"
# secondly: calling kvm.init directly (/etc/init.d/kvm.init info)
#	calling kvm.init directly, the script should output
#	(if possibly in a nice form) information about ALL running vm's.

if [ "$1" = "init" ] || [ -z $1 ]; then
	echo "VM Overview"

	for r_vm in ${PID_DIR}/*.pid; do
		if [ -e ${r_vm} ]; then
			pid="`cat ${r_vm}`"
			uptime="`ps -o "etime=" ${pid}`"
			starttime="`ps -o "lstart=" ${pid}`"
			VM_NAME="`echo ${r_vm}|sed "s|"${PID_DIR}/"||g"`"
			VM_NAME=${VM_NAME%.pid}

			if ( `ps -p ${pid} -f --no-heading | grep "spice" > /dev/null 2>&1` ); then
				VM_REMOTE_ACCESS="spice"
				address_port="`echo "info spice" \
					| ${NC} --unix -q1 ${PID_DIR}/${VM_NAME}.sock 2>&1 \
					| grep --only-matching --perl-regex "(?<=address\:).*[0-9]" \
					| head -n1`"
			elif ( `ps -p ${pid} -f --no-heading | grep "vnc" > /dev/null 2>&1` ); then
				VM_REMOTE_ACCESS="vnc"
				address_port="`echo "info vnc" \
					| ${NC} --unix -q1 ${PID_DIR}/${VM_NAME}.sock 2>&1 \
					| grep --only-matching --perl-regex "(?<=address\:).*[0-9]" \
					| head -n1`"
			else
				VM_REMOTE_ACCESS="NONE"
				address_port="NONE"
			fi

			qtap_dev="`echo "info network" \
				| ${NC} --unix -q1 ${PID_DIR}/${VM_NAME}.sock 2>&1 \
				| grep --only-matching --perl-regex "(?<=ifname\=).*[0-9]"`"
			
			mac_addr="`echo "info network" \
				| ${NC} --unix -q1 ${PID_DIR}/${VM_NAME}.sock 2>&1 \
				| grep --only-matching --perl-regex "(?<=macaddr\=).*[a-fA-F0-9]"`"

			[ -z ${qtap_dev} ] && qtap_dev="NONE"
			[ -z ${mac_addr} ] && mac_addr="NONE"

			if ( `ps -p ${pid} -f --no-heading | grep "snapshot" > /dev/null 2>&1` ); then
				snapshot="yes"
			else
				snapshot="no"
			fi

			echo " * ${VM_NAME} (PID:${pid})"
			echo "   Snapshotmode: ${snapshot}"
			echo "   Uptime: ${uptime} (started @ ${starttime})"
			echo "   Network: ${VM_REMOTE_ACCESS} @${address_port} (${mac_addr}) on ${qtap_dev}"
			echo

		fi
	done
else
	# default settings
	address_port="NONE"
	qtap="NONE"
	VM_NAME="${1}"
	source /etc/conf.d/kvm.${1}

	# get the information
	if [ -e ${PID_DIR}/${VM_NAME}.pid ]; then
		pid="`cat ${PID_DIR}/${VM_NAME}.pid`"
		uptime="`ps -o "etime=" ${pid}`"
		starttime="`ps -o "lstart=" ${pid}`"
		if [ -n "${VM_REMOTE_ACCESS}" ]; then
			if [ "$(echo ${VM_REMOTE_ACCESS} | cut -d';' -f1 )" = "spice" ]; then
				address_port="`echo "info spice" \
					| ${NC} --unix -q1 ${PID_DIR}/${VM_NAME}.sock 2>&1 \
					| grep --only-matching --perl-regex "(?<=address\:).*[0-9]" \
					| head -n1`"
			elif [ "$(echo ${VM_REMOTE_ACCESS} | cut -d';' -f1)" = "vnc" ]; then
				address_port="`echo "info vnc" \
					| ${NC} --unix -q1 ${PID_DIR}/${VM_NAME}.sock 2>&1 \
					| grep --only-matching --perl-regex "(?<=address\:).*[0-9]" \
					| head -n1`"
			else
				echo "${VM_REMOTE_ACCESS} not valid"
			fi
		fi

		if ! [ "$(echo ${VM_NETWORK}| cut -d';' -f1)" = "none" ]; then
			if [ "$(echo ${VM_NETWORK} | cut -d';' -f1)" = "tap" ]; then
				qtap_dev="`echo "info network" \
					| ${NC} --unix -q1 ${PID_DIR}/${VM_NAME}.sock 2>&1 \
					| grep --only-matching --perl-regex "(?<=ifname\=).*[0-9]"`"
			fi
			if [ -z "$(echo ${VM_NETWORK} | cut -d';' -f2)" ]; then
				mac_addr="`echo "info network" \
					| ${NC} --unix -q1 ${PID_DIR}/${VM_NAME}.sock 2>&1 \
					| grep --only-matching --perl-regex "(?<=macaddr\=).*[a-fA-F0-9]"`"
			else
				mac_addr="$(echo ${VM_NETWORK}|cut -d';' -f2)"
			fi
		fi
	fi

	echo "Information about: ${VM_NAME}"
	if ( ${VM_ENABLE_SNAPSHOTMODE} ); then
		echo " ** VM is running in SNAPSHOT mode! **"
	fi
	echo
	echo " VM started at: ${starttime}"
	echo " Uptime: ${uptime}"
	echo " PID: ${pid}"
	echo
	echo " Remote Access via: $(echo ${VM_REMOTE_ACCESS}|cut -d';' -f1)"
	echo " Ip/Port: ${address_port}"
	echo
	echo " Network Typ: $(echo ${VM_NETWORK}|cut -d';' -f1)"
	echo " qdap-device: ${qtap_dev}"
	echo " MAC-Address: ${mac_addr}"
fi
