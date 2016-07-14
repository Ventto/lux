Lightmano
===================

## Description
Lightmano is a simple shell script (currently a first draft) to control
backlight on GNU/Linux. It aims to have the same features than
[Light](https://github.com/haikarainen/light) and a bit more to offset the tiny
lack of configuration.

## Features (currently)

* Set a minimum brightness value, to make the screen plunges into total darkness.
It happens sometimes from a certain value, if you decrease the brightness until
before 0 the result is the same. So ergonomicly that value could be the minimum.

* Set a maximum brightness value, as some controllers, the max value is 100 but
when 100 is achieved the screen is pitch black. So the friendly max is 99.
That's why by default after reboot the brightness is set 99 automatically.
For the sake of ergonomy, when we keep pressing the shortcut to increase
the brightness like nerotic, we expect well lit screen. Moreover for some
dazzling backlightings, the last 5% or 10% could be useless.

* Figure out the best max-brightness-value controller.

## Installation

'Currently' the way to edit the write-protected *brightness* file for any
controller is to add the following line in your *sudoers* file via
**sudo visudio**:

`<username> ALL=NOPASSWD: /usr/bin/tee /sys/class/backlight/*/brightness`

Run the script.

## Usage
<code> lightmano [OPTION]... </code>

The option values are positive integers.
To enable percent mode, add '%' after the value.

### Config options
* -m:	Set the minimum brightness
* -M:	Set the maximum brightness
* -c:	Set the controller

### Brightness setter options (can be used in conjunction with config options)
* -a:	Add value
* -s:	Subtract value
* -S:	Set the current brightness value

### No option (read values)

## Examples
```
$ lightmano -S 35
$ lightmano -m 30 -M 99 -a 10
$ lightmano -a 15%
$ lightmano -m 10 -M 80 -S 50%
$ lightmano -c /sys/class/backlight/nv_backlight -s 10
```

## TODO
* Automatically figure out the functional controller
* Less intrusive method to edit the write-protected *brightness* file
* Backup brightness value
