#!/bin/sh
# Copyright 2017 Thomas "Ventto" Venriès <thomas.venries@gmail.com>
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
usage() {
    echo 'Usage: lux [OPTION]...
Brightness option values are positive integers.
Percent mode, add "%" after values (operation options only).

Without option, it prints controller name and brightness info:
{controller} {min;value;max}

Information:
  -h  Prints this help and exits
  -v  Prints version info and exists

Thresholds (can be used in conjunction):
  -m <value>
      Set the brightness min (min < max)
  -M <value>
      Set the brightness max (max > min)

Operations (with percent mode):
  -a <value>[%]
      Add value
  -s <value>[%]
      Subtract value
  -S <value>[%]
      Set the brightness value (set thresholds will be ignored)

Controllers:
  -c <path>
      Set the controller to use (needs argument).
      Use any controller name in /sys/class/backlight as argument.
      Otherwise a controller is automatically chosen (default).
'
}

version() {
    echo 'Lux 1.1
Copyright (C) 2017 Thomas "Ventto" Venriès.

License GPLv3+: GNU GPL version 3 or later
<http://gnu.org/licenses/gpl.html>.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR
PURPOSE
'
}

no_conjunction() {
    while [ "$#" -ne 0 ]; do $1 && return 1; shift; done; return 0
}

arg_err() {
    usage; exit 2
}

is_positive_int() {
    echo "${1}" | grep -E '^[0-9]+$' > /dev/null && return 0; return 1
}

is_percentage() {
    echo "${1}" | grep -E '%$' > /dev/null && return 0; return 1
}

check_perm() {
    _brightness="${1}"
    udev_rule="/etc/udev/rules.d/99-lux.rules"

    if [ ! -w "${_brightness}" ] ; then
        if [ "$(id -u)" -ne 0 ]; then
            if ! id -nG "${USER}" | grep video > /dev/null ; then
                echo "Use sudo once to setup group permissions,"
                echo "to access to controller's brightness from user."
            else
                echo "To setup the group permissions permanently, you need to logout/login."
            fi
            exit
        fi
    fi

    if [ "$(id -u)" -eq 0 ]; then
        if ! cut -d: -f1 /etc/group | grep video > /dev/null ; then
            echo "Group ~video~ does not exist."
            exit 1
        fi

        if [ "$(ls -l "${_brightness}" | cut -d' ' -f4)" != 'video' ]; then
            if [ ! -f "${udev_rule}" ] ; then
                echo "${udev_rule}: missing file."
                exit 1
            fi
            udevadm control -R
            udevadm trigger -c add -s backlight
        fi

        if ! id -nG ${SUDO_USER} | grep video > /dev/null ; then
            usermod -a -G video "${SUDO_USER}"
            echo "User has been added to ~video~ group."
            echo "To setup the group permissions permanently, you need to logout/login."
            exit
        fi
    fi
}

main() {
    mFlag=false
    MFlag=false
    cFlag=false
    aFlag=false
    sFlag=false
    SFlag=false
    percent_mode=false

    while getopts 'hvm:M:c:a:s:S:' opt; do
        case $opt in
            h)  usage  ; exit;;
            v)  version; exit;;
            m)  ! is_positive_int "$OPTARG" && arg_err
                mFlag=true
                mArg="$OPTARG"
                ;;
            M)  ! is_positive_int "$OPTARG" && arg_err
                MFlag=true
                MArg="$OPTARG"
                ;;
            c)  controller_path="/sys/class/backlight/$OPTARG"
                if [ ! -d "${controller_path}" ] ; then
                    echo "${controller_path}: controller not found."
                    exit
                fi
                [ "$#" -eq 2 ] && arg_err
                cFlag=true
                cArg="${controller_path}"
                ;;
            a)  ! no_conjunction "${sFlag}" "${SFlag}" && arg_err
                if is_percentage "$OPTARG"; then
                    percent_mode=true
                    OPTARG=$(echo "$OPTARG" | cut -d % -f 1)
                fi
                ! is_positive_int "$OPTARG" && arg_err
                aFlag=true
                valArg="$OPTARG"
                ;;
            s)  ! no_conjunction "${aFlag}" "${SFlag}" && arg_err
                if is_percentage "$OPTARG"; then
                    percent_mode=true
                    OPTARG=$(echo "$OPTARG" | cut -d % -f 1)
                fi
                ! is_positive_int "$OPTARG" && arg_err
                sFlag=true
                valArg="$OPTARG"
                ;;
            S)  ! no_conjunction "${aFlag}" "${sFlag}" && arg_err
                if is_percentage "$OPTARG"; then
                    percent_mode=true
                    OPTARG=$(echo "$OPTARG" | cut -d % -f 1)
                fi
                ! is_positive_int "$OPTARG" && arg_err
                SFlag=true
                valArg="$OPTARG"
                ;;
            \?) usage; exit 2;;
            :)  usage; exit 2;;
        esac
    done

    best_max=-1

    if ${cFlag} ; then
        best_controller=${cArg}
        best_max=$(cat "${best_controller}/max_brightness")
    # Try to find the best-max-value controller
    else
        for i in $(echo /sys/class/backlight/*) ; do
            [ "${i:-1}" = '*' ] && break
            max=$(cat "${i}/max_brightness")
            if [ "${best_max}" -lt "${max}" ] ; then
                best_max="${max}"
                best_controller="${i}"
            fi
        done
        if [ -z "${best_controller}" ]; then
            echo "No backlight controller detected"
            exit
        fi
    fi

    file="${best_controller}/brightness"

    check_perm "${file}"

    brightness=$(cat "${file}")
    best_max=$((best_max - 1))

    # Needs to display the choosen controler
    if [ "$#" -eq 0 ] ; then
        echo "${best_controller} 0;${brightness};${best_max}"
        exit
    fi

    shift "$((OPTIND - 1))"

    if ${SFlag} ; then
        ${percent_mode} && valArg=$(( best_max * valArg / 100 ))
        [ "$valArg" -lt 0 ] && valArg=0
        [ "$valArg" -gt "$best_max" ] && valArg="${best_max}"
        echo "${valArg}" | tee "${file}"
        exit
    fi

    ${mFlag} && own_min="${mArg}" || own_min=0
    ${MFlag} && own_max="${MArg}" || own_max="${best_max}"

    if [ $(( own_max - own_min )) -le 0 ] || \
        [ $(( own_max - own_min )) -gt "${best_max}" ] ; then
        arg_err
    fi

    [ "$brightness" -lt "$own_min" ] && brightness="${own_min}"
    [ "$brightness" -gt "$own_max" ] && brightness="${own_max}"

    ${percent_mode} && valArg=$(( (own_max - own_min) * valArg / 100 ))

    if ${aFlag} ; then
        value=$(( brightness + valArg ))
        [ "$value" -gt "$own_max" ] && value="${own_max}"
        echo "${value}" | tee "${file}"
    elif ${sFlag} ; then
        value=$(( brightness - valArg ))
        [ "$value" -lt "$own_min" ] && value="${own_min}"
        echo "${value}" | tee "${file}"
    else
        arg_err
    fi
}

main "$@"
