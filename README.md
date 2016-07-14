Lightmano
===================

## Description
Lightmano is a simple shell script (currently a first draft) to control backlight on GNU/Linux.
It aims to have the same features than [Light](https://github.com/haikarainen/light)
and a bit more to offset the tiny lack of configuration.

## Features (currently)

* Set a minimum brightness value, to make the screen plunges into total darkness.
It happens sometimes from a certain value, if you decrease the brightness until
before 0 the result is the same. So ergonomicly that value could be the minimum.

* Set a maximum brightness value, as some controllers, the max value is 100 but
when 100 is achieved the screen is pitch black. So the friendly max is 99.
Usually, when we keep pressing the shortcut to increase the brightness like nerotic,
we expect dazzling screen.

* Figure out the best max-brightness-value controller.

## Installation

Currently the way to edit the write-protected *brightness* file is to add the
following line in your *sudoers* file via **sudo visudio**:

`<username> ALL=NOPASSWD: /usr/bin/tee /sys/class/backlight/<controller_name>/brightness`

Conscious, that was a lazy method.
In the near future, with more time (udev rule or root the script)

## Usage
<code> lightmano [OPTION]... </code>

The option values are positive integers.

### To set the thresholds:
* -m:	Set the minimum brightness
* -M:	Set the maximum brightness (useless if greater than the real max
brightness value)
* -c:	Set the controller

### To set the brightness (can be use with the threshold options):
* -a:	Add value
* -s:	Subtract value
* -S:	Set the current brightness value

### No option (read values)

## TODO
* Automatically figure out the functional controller
* Less intrusive method to edit the write-protected *brightness* file
* Add percent mode
* Backup brightness value
