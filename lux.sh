#!/bin/sh
#
# Copyright (c) 2020 Thomas "Ventto" Venriès <thomas.venries@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
usage() {
    echo 'Usage: lux OPERATION [-c CONTROLLER_NAME] [-m MIN] [-M MAX]

Brightness option values are positive integers.
Percent mode, add "%" after values (operation options only).
Without option, it prints controller name and brightness info.

Information:
  -h  Prints this help and exits
  -v  Prints version info and exits

Thresholds (must be used in conjunction with an operation):
  -m MIN
      Set the brightness MIN (raw value)
  -M MAX
      Set the brightness MAX (raw value)

Operations (with percent mode):
  -a VALUE[%]
      Increase the brightness VALUE
  -s VALUE[%]
      Subtract the brightness VALUE
  -S VALUE[%]
      Set the brightness VALUE (thresholds will be ignored)
  -g Print the current brightness raw value
  -G Print the current brightness percentage

Controllers:
  -c CONTROLLER_NAME
      Set the controller to use.
      Use any CONTROLLER_NAME in /sys/class/backlight.
'
}

version() {
    echo 'Lux 1.21
Copyright (C) 2020 Thomas "Ventto" Venriès.

License MIT
<https://opensource.org/licenses/MIT>.
'
}

no_conjunction() {
    while [ "$#" -ne 0 ]; do $1 && return 1; shift; done
}

arg_err() {
    usage; exit 2
}

is_positive_int() {
    echo "${1}" | grep -E '^[0-9]+$' >/dev/null 2>&1 || return 1
}

is_percentage() {
    echo "${1}" | grep -E '%$' >/dev/null 2>&1 || return 1
}

check_perm() {
    _ctrl="${1}"
    udev_rule="/etc/udev/rules.d/99-lux.rules"

    if [ ! -w "${_ctrl}/brightness" ] ; then
        if [ "$(id -u)" -ne 0 ]; then
            if ! id -nG "${USER}" | grep video >/dev/null 2>&1; then
                echo "Use sudo once to setup group permissions,"
                echo "to access to controller's brightness from user."
            else
                echo "To setup the group permissions permanently, you need to logout/login."
            fi
            exit
        fi
    fi

    if [ "$(id -u)" -eq 0 ]; then
        if ! cut -d: -f1 /etc/group | grep video >/dev/null 2>&1; then
            echo "Group ~video~ does not exist."
            exit 1
        fi

        if [ -z "$(find "${_ctrl}" -name 'brightness' -group video)" ]; then
            if [ ! -f "${udev_rule}" ] ; then
                echo "${udev_rule}: missing file."
                exit 1
            fi
            udevadm control -R
            udevadm trigger -c add -s backlight
        fi

        if ! id -nG "${SUDO_USER}" | grep video >/dev/null 2>&1; then
            usermod -a -G video "${SUDO_USER}"
            echo "User has been added to ~video~ group."
            echo "To setup the group permissions permanently, you need to logout/login."
            exit
        fi
    fi
}

main() {
    gFlag=false
    mFlag=false
    MFlag=false
    cFlag=false
    aFlag=false
    sFlag=false
    SFlag=false
    percent_mode=false

    while getopts 'hvgGm:M:c:a:s:S:' opt; do
        case $opt in
            h)  usage  ; exit;;
            v)  version; exit;;
            g|G)  ! no_conjunction "${sFlag}" "${SFlag}" "${aFlag}" && arg_err
                [ "$opt" = 'G' ] && percent_mode=true
                gFlag=true
                ;;
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
            a)  ! no_conjunction "${sFlag}" "${SFlag}" "${gFlag}" && arg_err
                if is_percentage "$OPTARG"; then
                    percent_mode=true
                    OPTARG=$(echo "$OPTARG" | cut -d'%' -f1)
                fi
                ! is_positive_int "$OPTARG" && arg_err
                aFlag=true
                valArg="$OPTARG"
                ;;
            s)  ! no_conjunction "${aFlag}" "${SFlag}" "${gFlag}" && arg_err
                if is_percentage "$OPTARG"; then
                    percent_mode=true
                    OPTARG=$(echo "$OPTARG" | cut -d'%' -f1)
                fi
                ! is_positive_int "$OPTARG" && arg_err
                sFlag=true
                valArg="$OPTARG"
                ;;
            S)  ! no_conjunction "${aFlag}" "${sFlag}" "${gFlag}" && arg_err
                if is_percentage "$OPTARG"; then
                    percent_mode=true
                    OPTARG=$(echo "$OPTARG" | cut -d'%' -f1)
                fi
                ! is_positive_int "$OPTARG" && arg_err
                SFlag=true
                valArg="$OPTARG"
                ;;
            \?) usage; exit 2;;
            :)  usage; exit 2;;
        esac
    done

    if ${cFlag} ; then
        best_controller=${cArg}
        best_max=$(cat "${best_controller}/max_brightness")
    # Try to find the best-max-value controller
    else
        best_max=-1
        best_controller=''
        for ctrl in /sys/class/backlight/*; do
            [ ! -d "${ctrl}" ] && break
            [ ! -r "${ctrl}/max_brightness" ] && break
            max="$(cat "${ctrl}/max_brightness")"
            if [ "${best_max}" -lt "${max}" ] ; then
                best_max="${max}"
                best_controller="${ctrl}"
            fi
        done
        if [ -z "${best_controller}" ]; then
            echo "No backlight controller detected"
            exit
        fi
    fi

    check_perm "${best_controller}"

    file="${best_controller}/brightness"
    brightness=$(cat "${file}")
    best_max=$((best_max - 1))

    # Display controller information if no argument
    if [ "$#" -eq 0 ] ; then
        echo "${best_controller} 0;${brightness};${best_max}"
        exit
    fi

    if ${gFlag}; then
        ${percent_mode} && { echo "$((brightness * 100 / best_max))%"; exit; }
        echo "$brightness"
        exit
    fi

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
