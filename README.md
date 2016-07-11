Lightmano
===================

# Description
Lightmano is a shell simple script (currently a first draft) to control backlight on GNU/Linux.
It aims to have the same features than [Light](https://github.com/haikarainen/light)
and a bit more to offset the tiny lack of configuration.

# Features

*  Set a minimum brightness value (default value = 0) the limit to make
the screen plunges into total darkness.
* Set a maximum brightness value, as some controllers, the max value is 100 but
when 100 is achieved it is pitch black. So the friendly max is 99. When we use
press the shortcut to increase the brightness like nerotic, we don't expect it.
Usually, it is when we want to decrease the brightness level.

# Installation

Currently the way to edit the write-protected *brightness* file is to add the
following line in your *sudoers* file via **sudo visudio**:

`<username> ALL=NOPASSWD: /usr/bin/tee /sys/class/backlight/<controller_name>/brightness`

Conscious, that was a lazy method.
In the near future, with more time, I am going to turn to an udev rule or
something else less intrusive.

# Usage
<code> brightness.sh [option] [value] </code>

The value has to be a **positive decimal**.

### To set the thresholds:
* -m:	Set the minimum brightness
* -M:	Set the maximum brightness (useless if greater than the real max
brightness value)

### To se the brightness (can be use with the threshold options):
* -c:	Directly set the current brightness value
* -a:	Add value
* -s:	Subtract value


## TODO
* Automatically figure out the functional controller
* Less intrusive method to edit the write-protected *brightness* file
* Add an option to let the user choose the controller
* Add a pertinent percent mode according to the new interval (with -m/-M options)
