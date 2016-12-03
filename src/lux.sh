#!/bin/bash -
#
# Copyright 2016 Thomas "Ventto" Venriès <thomas.venries@gmail.com>
#
# Lux is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Lux is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Lux.  If not, see <http://www.gnu.org/licenses/>.
usage() {
	echo -e "Usage: lux [OPTION]...
Brightness's option values are positive integers.\n
For percent mode: add '%' after values. Percent mode can only be used with
brightness value options.

Information:
  blank:\tPrints controller's name and brightness info;
  \t\tpattern: {controller} {min;value;max}
  -h:\t\tPrints this help and exits
  -v:\t\tPrints version info and exists

Brightness threshold options (can be used in conjunction):
  -m:\t\tSet the brightness min
  -M:\t\tSet the brightness max

Brightness value options (can not be use in conjunction):
  -a:\t\tAdd value
  -s:\t\tSubtract value
  -S:\t\tSet the brightness value

Controller options (can be used with brightness options):
  -c:\t\tSet the controller to use (needs argument). Use any controller name in
  \t\t/sys/class/backlight/ as argument.\n\t\tOtherwise a controller is automatically chosen (default)\n"
}

version() {
	echo -e "Lux 0.9
Copyright (C) 2016 Thomas \"Ventto\" Venries.\n
License GPLv3+: GNU GPL version 3 or later
<http://gnu.org/licenses/gpl.html>.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR
PURPOSE\n"
}

no_conjunction() {
	while [ $# -ne 0 ]; do
		[ "$1" = true ] && break || shift
	done
	[ $# -eq 0 ] && echo 1 || echo 0
}

is_positive_int() {
	[[ "$1" =~ ^[0-9]+$ ]] && echo 1 || echo 0
}

is_percentage() {
	[ -z "$(echo $1 | grep -e "%$")" ] && echo 0 || echo 1
}

check_perm() {
	local _brightness_file=$1
	local udev_rule="/etc/udev/rules.d/99-lux.rules"

	if [ ! -w "${_brightness_file}" ]; then
		if [ ! -f "${udev_rule}" ]; then
			echo "${udev_rule} is missing."
			exit 1
		fi
		if [ ! $(ls -ld ${_brightness_file} | awk '{print $4}') == "video" ]; then
			sudo udevadm control -R && \
			sudo udevadm trigger -c add -s backlight
		fi
		if [ ! "$(id -nG "${USER}" | grep -wo "video")" == "video" ]; then
			sudo usermod -a -G video ${USER}
		fi
		echo "To run it without sudo, you need to logout/login."
		echo 1
	else
		echo 0
	fi
}

main() {
	local mFlag=false
	local MFlag=false
	local cFlag=false
	local aFlag=false
	local sFlag=false
	local SFlag=false

	local percent_mode=false

	OPTIND=1
	while getopts "hvm:M:c:a:s:S:" opt; do
		case $opt in
			h)	usage	&& exit 0;;
			v)	version	&& exit 0;;
			m)	[ $(is_positive_int $OPTARG) == "0" ] && usage && exit 2
				mFlag=true
				mArg=$OPTARG
				;;
			M)	[ $(is_positive_int $OPTARG) == "0" ] && usage && exit 2
				MFlag=true
				MArg=$OPTARG
				;;
			c)	local controller_path="/sys/class/backlight/$OPTARG"
				if [ ! -d "$controller_path" ]; then
					echo "$controller_path: controller not found."
					exit 0
				fi
				cFlag=true
				cArg=$controller_path
				;;
			a)	[ $(no_conjunction $sFlag $SFlag) != "1" ] && usage && exit 2
				if [ "$(is_percentage $OPTARG)" == "1" ]; then
					percent_mode=true
					OPTARG=$(echo $OPTARG | cut -d % -f 1)
				fi
				[ $(is_positive_int $OPTARG) == "0" ] && usage && exit 2
				aFlag=true
				valArg=$OPTARG
				;;
			s)	[ $(no_conjunction $aFlag $SFlag) != "1" ] && usage && exit 2
				if [ "$(is_percentage $OPTARG)" == "1" ]; then
					percent_mode=true
					OPTARG=$(echo $OPTARG | cut -d % -f 1)
				fi
				[ $(is_positive_int $OPTARG) == "0" ] && usage && exit 2
				sFlag=true
				valArg=$OPTARG
				;;
			S)	[ $(no_conjunction $aFlag $sFlag) != "1" ] && usage && exit 2
				if [ "$(is_percentage $OPTARG)" == "1" ]; then
					percent_mode=true
					OPTARG=$(echo $OPTARG | cut -d % -f 1)
				fi
				[ $(is_positive_int $OPTARG) == "0" ] && usage && exit 2
				SFlag=true
				valArg=$OPTARG
				;;
			\?)	exit 2 ;;
			:)	exit 2 ;;
		esac
	done

	local best_controller=""
	local best_max=-1

	if [ "$cFlag" = true ] ; then
		best_controller=$cArg
		best_max=$(cat $best_controller/max_brightness)
	# Try to find the best-max-value controller
	else
		for i in $(echo /sys/class/backlight/*) ; do
			[ "${i: -1}" == "*"  ] && break
			max=$(cat ${i}/max_brightness)
			if (( "$best_max" < "$max" )) ; then
				best_max=$max
				best_controller=${i}
			fi
		done
		if [ -z "$best_controller"  ]; then
			echo "No backlight controller detected" && exit 0
		fi
	fi

	local file="$best_controller/brightness"

	check_perm ${file}

	local own_min=0
	local own_max=$(( best_max-1 ))
	local brightness=$(cat $file)

	if [ "$#" -eq 0 ]; then
		echo "$best_controller $own_min;$brightness;$own_max"; exit 0
	elif [ $# -eq 2 ] && [ "$cFlag" = true ]; then
		usage; exit 0
	fi

	[ "$mFlag" = true ] && own_min=$mArg
	[ "$MFlag" = true ] && own_max=$MArg

	if [ "$aFlag" = true ]; then
		if [ "$percent_mode" = true ]; then
			valArg=$(( (own_max - own_min) * valArg / 100 ))
		fi
		value=$(( brightness+valArg ))
		if (( $brightness == 0 )) ; then
			value=$(( own_min+valArg ))
		elif (( "$value" > "$own_max" )) ; then
			value=$own_max
		fi
		echo $value | /usr/bin/tee $file
	fi

	if [ "$sFlag" = true ]; then
		if [ "$percent_mode" = true ]; then
			valArg=$(( (own_max - own_min) * valArg / 100 ))
		fi
		value=$(( brightness-valArg ))
		(( $value <= $own_min )) && value=0
		echo $value | /usr/bin/tee $file
	fi

	if [ "$SFlag" = true ]; then
		if [ "$percent_mode" = true ]; then
			valArg=$(( own_min + (own_max - own_min) * valArg / 100 ))
		fi
		value=$valArg
		if (( $value > $own_max )) ; then
			value=$own_max
		elif (( $value < $own_min )) ; then
			value=0
		fi
		echo $value | /usr/bin/tee $file
	fi

	shift "$((OPTIND-1))"
}

main "$@"
