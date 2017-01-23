#!/usr/bin/env bash
# Copyright 2016 Thomas "Ventto" Venriès <thomas.venries@gmail.com>
#
# Lux is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Lux is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Lux.  If not, see <http://www.gnu.org/licenses/>.
set -e

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

Thresholds (can be used in conjunction):
  -m:\t\tSet the brightness min (min < max)
  -M:\t\tSet the brightness max (max > min)

Operations:
  -a:\t\tAdd value
  -s:\t\tSubtract value
  -S:\t\tSet the brightness value (set thresholds will be ignored)

Controllers:
  -c:\t\tSet the controller to use (needs argument).\n\t\tUse any controller name in /sys/class/backlight/ as argument.\n\t\tOtherwise a controller is automatically chosen (default)\n"
}

version() {
    echo -e "Lux 1.0
Copyright (C) 2016 Thomas \"Ventto\" Venries.\n
License GPLv3+: GNU GPL version 3 or later
<http://gnu.org/licenses/gpl.html>.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR
PURPOSE\n"
}

no_conjunction() {
    while [ "$#" -ne 0 ] && ! ${1} ; do shift ; done
    echo "$#"
}

arg_err() {
    usage && exit 2
}

is_positive_int() {
    [[ "${1}" =~ ^[0-9]+$ ]] && echo 1 || echo 0
}

is_percentage() {
    echo "${1}" | grep "%$" > /dev/null && echo 1 || echo 0
}

check_perm() {
    local _brightness=${1}
    local udev_rule="/etc/udev/rules.d/99-lux.rules"

    if [ ! -w "${_brightness}" ] ; then
        if [ "$(id -u)" != "0" ]; then
            if ! id -nG "${USER}" | grep video > /dev/null ; then
                echo "Use sudo once to setup group permissions,"
                echo "to access to controller's brightness from user."
            else
                echo "To setup the group permissions permanently, you need to logout/login."
            fi
            exit 0
        fi
    fi

    if [ "$(id -u)" == "0" ]; then
        if ! cut -d: -f1 /etc/group | grep video > /dev/null ; then
            echo "Group ~video~ does not exist."
            exit 1
        fi

        if ! ls -l "${_brightness}" | grep video > /dev/null ; then
            if [ ! -f "${udev_rule}" ] ; then
                echo "${udev_rule}: missing file."
                exit 1
            fi
            udevadm control --reload-rules
            udevadm trigger -c add -s backlight
        fi

        if ! id -nG "${SUDO_USER}" | grep video > /dev/null ; then
            usermod -a -G video "${SUDO_USER}"
            echo "User has been added to ~video~ group."
            echo "To setup the group permissions permanently, you need to logout/login."
            exit 0
        fi
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
            h)  usage   && exit 0 ;;
            v)  version && exit 0 ;;
            m)  [ "$(is_positive_int "$OPTARG")" == 0 ] && arg_err
                mFlag=true
                mArg=$OPTARG
                ;;
            M)  [ "$(is_positive_int "$OPTARG")" == 0 ] && arg_err
                MFlag=true
                MArg=$OPTARG
                ;;
            c)  local controller_path="/sys/class/backlight/$OPTARG"
                if [ ! -d "${controller_path}" ] ; then
                    echo "${controller_path}: controller not found."
                    exit 0
                fi
                cFlag=true
                cArg="${controller_path}"
                ;;
            a)  [ "$(no_conjunction ${sFlag} ${SFlag})" != 0 ] && arg_err
                if [ "$(is_percentage "$OPTARG")" == 1 ] ; then
                    percent_mode=true
                    OPTARG=$(echo "$OPTARG" | cut -d % -f 1)
                fi
                [ "$(is_positive_int "$OPTARG")" == 0 ] && arg_err
                aFlag=true
                valArg=$OPTARG
                ;;
            s)  [ "$(no_conjunction "${aFlag}" "${SFlag}")" != 0 ] && arg_err
                if [ "$(is_percentage "$OPTARG")" == 1 ] ; then
                    percent_mode=true
                    OPTARG=$(echo "$OPTARG" | cut -d % -f 1)
                fi
                [ "$(is_positive_int "$OPTARG")" == 0 ] && arg_err
                sFlag=true
                valArg=$OPTARG
                ;;
            S)  [ "$(no_conjunction "${aFlag}" "${sFlag}")" != 0 ] && arg_err
                if [ "$(is_percentage "$OPTARG")" == 1 ] ; then
                    percent_mode=true
                    OPTARG=$(echo "$OPTARG" | cut -d % -f 1)
                fi
                [ "$(is_positive_int "$OPTARG")" == 0 ] && arg_err
                SFlag=true
                valArg=$OPTARG
                ;;
            \?) exit 2 ;;
            :)  exit 2 ;;
        esac
    done

    local best_controller=""
    local best_max=-1

    if ${cFlag} ; then
        if [ "$#" -eq 2 ] ; then
            arg_err
        fi
        best_controller=${cArg}
        best_max=$(cat "${best_controller}/max_brightness")
    # Try to find the best-max-value controller
    else
        for i in $(echo /sys/class/backlight/*) ; do
            [ "${i:-1}" == "*" ] && break
            max=$(cat "${i}/max_brightness")
            if (( "${best_max}" < "${max}" )) ; then
                best_max=${max}
                best_controller=${i}
            fi
        done
        if [ -z "${best_controller}" ]; then
            echo "No backlight controller detected"
            exit 0
        fi
    fi

    local file="${best_controller}/brightness"

    check_perm "${file}"

    brightness=$(cat "${file}")
    best_max=$(( best_max - 1 ))

    # Needs to display the choosen controler
    if [ "$#" -eq 0 ] ; then
        echo "${best_controller} 0;${brightness};${best_max}"
        exit 0
    fi

    if ${SFlag} ; then
        ${percent_mode} && valArg=$(( best_max * valArg / 100 ))
        [ "$valArg" -lt 0 ] && valArg=0
        [ "$valArg" -gt "$best_max" ] && valArg=${best_max}
        echo "${valArg}" | /usr/bin/tee "${file}"
        shift "$((OPTIND - 1))"
        exit 0
    fi

    ${mFlag} && own_min=${mArg} || own_min=0
    ${MFlag} && own_max=${MArg} || own_max=${best_max}

    if [ $(( own_max - own_min )) -le 0 ] || \
        [ $(( own_max - own_min )) -gt "${best_max}" ] ; then
        arg_err
    fi

    [ "$brightness" -lt "$own_min" ] && brightness=${own_min}
    [ "$brightness" -gt "$own_max" ] && brightness=${own_max}

    ${percent_mode} && valArg=$(( (own_max - own_min) * valArg / 100 ))

    if ${aFlag} ; then
        value=$(( brightness + valArg ))
        [ "$value" -gt "$own_max" ] && value=${own_max}
        echo "${value}" | /usr/bin/tee "${file}"
    elif ${sFlag} ; then
        value=$(( brightness - valArg ))
        [ "$value" -lt "$own_min" ] && value=${own_min}
        echo "${value}" | /usr/bin/tee "${file}"
    else
        arg_err
    fi

    shift "$((OPTIND - 1))"
}

main "$@"
