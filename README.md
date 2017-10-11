Lux
===

[![License](https://img.shields.io/badge/license-GPLv3-blue.svg?style=flat)](https://github.com/Ventto/lux/blob/master/LICENSE)
[![Vote for lux](https://img.shields.io/badge/AUR-Vote_for-yellow.svg)](https://aur.archlinux.org/packages/lux/)

*Lux is a POSIX-compliant Shell script to easily control brightness on backlight-controllers.*

## Features

*  Mark out the brightness value by a min & max value. That can avoid making the screen plunges into total darkness. It happens sometimes if you set the brightness 0 or 100. So we should set the maximum 99 or/and minimum 1. Moreover that could be useful if between 1 and 20, the brightness seems to be the same for eyes (set the minimum 20).

* Set another backlight controller manually

* Figure out the best max-brightness-value controller without setting one.

## Installation

### Package Manager Utilities

```
$ yaourt -S lux
```

### Manually

* Install *lux*:

```
$ git clone https://github.com/Ventto/lux.git
$ cd lux
$ sudo make install
```

* To control the brightness level, you need to setup the relevant group permissions
permanently.<br />So first, run *lux* with sudo and then logout/login.

* If you are in a hurry, you can directly get these permissions properly in a new shell:

```
$ newgrp video
```

## Usage

```
lux [OPTION]...
```

Brightness's option values are positive integers.
Percent mode: add '%' after values (operation options only).

Without option, it prints controller name and brightness info:
{controller} {min;value;max}

#### Information:

* -h: Prints this help and exits
* -v: Prints version info and exists

#### Thresholds (raw values, can be used in conjunction):

* -m: Set the brightness min (natural integer, min < max)
* -M: Set the brightness max (natural integer, max < min)

#### Operations (with percent mode):

* -a: Add value
* -s: Subtract value
* -S: Set the brightness value (set thresholds will be ignored)

#### Controllers:
* -c: Set the controller to use (needs argument). Use any controller name in /sys/class/backlight/ as argument. Otherwise a controller is automatically chosen (default)


## Examples

* No option
```
$ lux
/sys/class/backlight/nv_backlight 0;43;99
```

* Set a value (useful for pitchblack-shortcut)
```
$ lux -S 0
```

* Increase the current of 15%
```
$ lux -a 15%
```

* Set the minimum 30, the maximum 99 and increase the current value of 10

```
$ lux -m 30 -M 99 -a 10
```

* Set the backlight controller and set the brightness value of 50
```
$ lux -c /sys/class/backlight/nv_backlight -S 50
```

## FAQ

### From 0 to 20, there is no difference.

Sometimes, it happens. You could set the minimum 20.<br>

```
lux -m 20 [OPTION]...
```

### Pitchblack at 100 ?

Set the maximum with 99.<br>

```
lux -M 99 [OPTION]...
```

### Set the brightness value after initializing an X session ?

```
echo "lux -S 10" >> $HOME/.xinitrc
```

