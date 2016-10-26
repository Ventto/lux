Lux
===

[![License](https://img.shields.io/badge/license-GPLv3-blue.svg?style=flat)](https://github.com/Ventto/lux/blob/master/COPYING)
[![Version](https://img.shields.io/badge/version-v0.9-blue.svg?style=flat)](https://github.com/Ventto/lux/releases)
[![Status](https://img.shields.io/badge/status-experimental-orange.svg?style=flat)](https://github.com/Ventto/lux/)
[![Language (Bash)](https://img.shields.io/badge/powered_by-Bash-brightgreen.svg)](https://www.gnu.org/software/bash/)

*Lux is a simple Bash script to easily control brightness on backlight-controllers.*

## Features

*  Mark out the brightness value by a min & max value. That can avoid making the screen plunges into total darkness. It happens sometimes if you set the brightness 0 or 100. So we should set the maximum 99 or/and minimum 1. Moreover that could be useful if between 1 and 20, the brightness seems to be the same for eyes (set the minimum 20).

* Set another backlight controller manually

* Figure out the best max-brightness-value controller without setting one.

## Installation

### Package Manager Utilities

```
$ yaourt -S lux (or)
$ pacaur -S lux
```

### Manually

* Download the sources:

```
$ git clone https://github.com/Ventto/lux.git
$ cd lux
```

* Copy the udev rules file in `/etc/udev/rules.d`:

```
$ sudo cp rules.d/99-lux.rules /etc/udev/rules.d
```

* Trigger the rules:

```
$ sudo udevadm control -R && sudo udevadm trigger -c add -s backlight
```

* Then add the user to the group:

```
$ sudo usermod -a -G video <user>
```

* To setup the relevant group permissions, you need to logout/login.
  Otherwise you could directly get these permissions in a shell:

```
$ newgrp video
```

* Run the script

```
$ cd src
$ chmod +x lux.sh
$ ./lux.sh
```

## Usage

```
lux [OPTION]...
```

Brightness's option values are positive integers.

For percent mode: add '%' after values. Percent mode can only be used with
brightness value options.

#### Information:

* blank:	Prints controller's name and brightness info;
  Pattern: {controller} {min;value;max}
* -h:	 Prints this help and exits
* -v:	 Prints version info and exists

#### Brightness threshold options (can be used in conjunction):

* -m: Set the brightness min
* -M: Set the brightness max

#### Brightness value options (can not be use in conjunction):

* -a:	 Add value
* -s:	 Subtract value
* -S: Set the brightness value

#### Controller options (can be used with brightness options):

* -c:		Set the controller to use (needs argument). Use any controller name in /sys/class/backlight/ as argument. Otherwise a controller is automatically chosen (default)

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

