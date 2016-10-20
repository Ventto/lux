Lux
===

*Lux is a simple shell script (currently a first draft) to control
backlight on GNU/Linux. It aims to have the same features than
[Light](https://github.com/haikarainen/light) and a bit more to offset the tiny
lack of configuration.*

## Features

* Set a minimum brightness value, to make the screen plunges into total darkness.
It happens sometimes from a certain value, if you decrease the brightness until
before 0 the result is the same. So ergonomicly that value could be the minimum.

* Set a maximum brightness value, as some controllers, the max value is 100 but
when 100 is achieved the screen is pitch black. So the friendly max is 99.
That's why by default after reboot the brightness is set 99 automatically.
For the sake of ergonomy, when we keep pressing the shortcut to increase
the brightness like nerotic, we expect well lit screen. Moreover for some
dazzling backlightings, the last 5% or 10% could be useless.

* Set a targeted controller

* Figure out the best max-brightness-value controller without setting one.

## Installation

Normally, users are prohibited to alter files in the sys filesystem. It's advisable to setup an "udev" rule to allow users in the "video" group to set the display brightness.

* To do so, place a file in /etc/udev/rules.d/90-backlight.rules containing:

```
SUBSYSTEM=="backlight", ACTION=="add", RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness"
SUBSYSTEM=="backlight", ACTION=="add", RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"
```

* Then add the user to the group:

```
$ sudo usermod -a -G video <user>
```

* To setup the relevant permissions at boot time.

## Usage
<code> lux [OPTION]... </code>
Brightness's option values are positive integers.

For percent mode: add '%' after values. Percent mode can only be used with
brightness value options.

#### Information:
* blank:	Prints controller's name and brightness info;
  Pattern: {controller} {min;value;max}
* -h:		Prints this help and exits
* -v:		Prints version info and exists

#### Brightness threshold options (can be used in conjunction):
* -m:		Set the brightness min
* -M:		Set the brightness max

#### Brightness value options (can not be use in conjunction):
* -a:		Add value
* -s:		Subtract value
* -S:		Set the brightness value

#### Controller options (can be used with brightness options):
* -c:		Set the controller to use (needs argument). <br />
  Use any controller name in /sys/class/backlight/ as argument.<br/>
  Otherwise a controller is automatically chosen (default)

## Examples
```
$ lux
/sys/class/backlight/nv_backlight: 0;43;99

$ lux -S 35
$ lux -a 15%
$ lux -s 30

$ lux -m 30 -M 99 -a 10
$ lux -m 10 -M 80 -S 50%

$ lux -c /sys/class/backlight/nv_backlight -s 10
```

## FAQ
Anwsers are only written to inspire you. They do not reflect your own configuration.

### Set the brightness value at startx ?
`echo "lux -S {row value|percent value}" > $HOME/.xinitrc`

### From 0 to 20, there is no difference. A lead ?
Sometimes, it happens. Lux was partially written to troubleshoot it.<br>
Set the minimum with 20.<br>
`lux [-a|-s|-S] {row value|percent value} -m 20`

### Pitchblack at 100 ?
Set the maximum with 99.<br>
`lux [-a|-s|-S] {row value|percent value} -M 99`


## TODO

* Automatically figure out the functional controller
* Less intrusive method to edit the write-protected *brightness* file
* Add -G option to display adapted brightness percentage according to min/max settings
Example:
```
$ lux
/sys/class/backlight/nv_backlight: 0;43;99   <-- output: row values from ./nv_backlight/

$ lux -m 10 -M 80 -G   <-- gap=80-10=70, current=43, 43*70/100~=30%
30%                          <-- output: percent value (<> row value)
```
* Keep the last brightness value after rebooting
