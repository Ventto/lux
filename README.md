Lux
===

[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](https://github.com/Ventto/lux/blob/master/LICENSE)
[![Vote for lux](https://img.shields.io/badge/AUR-Vote_for-yellow.svg)](https://aur.archlinux.org/packages/lux/)

*Lux is a POSIX-compliant Shell script to control brightness*

## Perks

* [x] **No requirement**: POSIX-compliant (minimal: *usermod, udevadm*)
* [x] **Lightweight**: ~200 lines
* [x] **Auto**: Find the best max-brightness-value controller automatically
* [x] **Threshold**: Restrict brightness value with min/max relevant limits

## Installation

### Package Manager Utilities

```bash
$ pacman -S lux
```

### Manually

* Install *lux*:

```bash
$ git clone https://github.com/Ventto/lux.git
$ cd lux
$ sudo make install
```

* To control the brightness level, you need to setup the relevant group permissions
permanently.<br />So first, run *lux* with `sudo` and then logout/login.

* If you are in a hurry, you can directly get these permissions properly in a new shell:

```
$ newgrp video
```

## Usage

```
Usage: lux OPERATION [-c CONTROLLER_NAME] [-m MIN] [-M MAX]

Brightness option values are positive integers.
Percent mode, add "%" after values (operation options only).
Without option, it prints controller name and brightness info.

Information:
  -h  Prints this help and exits
  -v  Prints version info and exists

Thresholds (can be used in conjunction):
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
```

## Examples

* Print information about brightness value:

```bash
$ lux
/sys/class/backlight/nv_backlight 0;1000;2000  # { current: 1000, max: 2000 }

$ lux -g
1000

$ lux -G
50%
```

* Set the brightness value to zero (useful for pitchblack-shortcut):

```bash
$ lux -S 0
```

* Increase the brightness:

```bash
$ lux -a 15%    (percentage)
$ lux -a 15     (raw value)
```

* Limit the value between [500;1999] and increase the brightness:

```bash
$ lux -g
1990

$ lux -m 500 -M 1999 -a 10

$ lux -g
1999
```

* Set the backlight controller manually and set the brightness:

```bash
$ ls /sys/class/backlight
intel_backlight

$ lux -c intel_backlight -S 50
```

## FAQ

### The max is 2000. Setting the value from 1 to 500 seems to do nothing.

* Set the minimum of 500:

```bash
$ lux -m 500 [OPTION]...
```

### Pitch black when the brightness equals the maximum, how avoiding this ?

```bash
$ cat /sys/class/backlight/intel_backlight/max_brightness
2000
$ lux -M 1999 ...
```

### Set the brightness value after initializing an X session ?

```bash
$ echo "lux -S 75%" >> $HOME/.xinitrc
```
