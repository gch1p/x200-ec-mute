#!/bin/bash

SCRIPTNAME="$0"
VERBOSE=
MODE=
REGISTER=0x03
DEPS="ectool grep awk"

set -e

die() {
	>&2 echo "$@"
	exit 1
}

usage() {
	local exitcode="$1"
	[ -z "$exitcode" ] && exitcode=0
	echo "Usage: $SCRIPTNAME [-v] on|off|status"
	exit $exitcode
}

verbose() {
	if [ -n "$VERBOSE" ]; then
		>&2 echo "$@"
	fi
}

installed() {
	command -v "$1" >/dev/null
}

read_reg() {
	echo "0x$(ectool -d | grep '^00:' | awk '{ print $5 }')"
}

write_reg() {
	local val="$1"

	# convert decimal to hex
	val="0x$(printf "%x" "$val")"

	verbose "new reg value: $val"

	ectool -w $REGISTER -z $val >/dev/null || die "Error: failed to write to the EC"

	verbose "new value $val has been written to register $REGISTER";
}

[[ $EUID == 0 ]] || die "This tool must be run as root."
[[ $# < 1 ]] && usage

for prog in $DEPS; do
	if ! installed $prog; then
		die "Error: $prog not found"
	fi
done

while [[ $# > 0 ]]; do
	case $1 in
		-v)
			VERBOSE=1
			;;

		on | off | status)
			MODE=$1
			;;

		*)
			die "Error: $1: unrecognized argument"
			;;
	esac
	shift
done

[ -z "$MODE" ] && usage 1

# read the register
reg=$(read_reg)
verbose "current reg value: $reg"

case $MODE in 
	status)
		if (( reg & 0x40 )); then
			echo "Enabled"
		else
			echo "Disabled"
		fi
		;;

	on)
		# set bit 6
		reg=$(( reg | 0x40 ))
		write_reg "$reg"
		;;

	off)
		# clear bit 6
		reg=$(( reg & 0xbf ))
		write_reg "$reg"
		;;
esac
