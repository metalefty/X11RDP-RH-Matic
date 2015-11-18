X11RDP-RH-Matic
===============
[xrdp/x11rdp](https://github.com/neutrinolabs/xrdp) install helper tool for Red Hat based distributions. This utility is inspired by [X11RDP-o-Matic](https://github.com/scarygliders/X11RDP-o-Matic). To talk straight, Red Hat version of X11RDP-o-Matic.


Usage
----
```
$ git clone https://github.com/metalefty/X11RDP-RH-Matic.git
$ cd X11RDP-RH-Matic
$ ./X11RDP-RH-Matic.sh
```

Supported Distributions
----

Currently, X11RDP-RH-Matic is developed on CentOS 6.6 and tested following
distributions. It may work on other RHEL clone distributions. Please report
if you confirmed it works.

- CentOS release 6.5 (Final)
- CentOS release 6.6 (Final) reported by Michael Niehren
- Scientific Linux release 6.5 (Carbon)

Now RHEL/CentOS 7 or later are experimentally supported.

TODOs
----

There's nothing major TODOs so far.


Experimental Features
----
X11RDP-RH-Matic experimentally supports the build of xrdp xorg driver. Run with
"--with-xorg-driver" option. When you want to build xorg driver, probably you
don't need X11rdp then also add "--nox11rdp" option.

```
$ ./X11RDP-RH-Matic.sh --with-xorg-driver --nox11rdp
```

You'll probably be required to edit /etc/pam.d/xserver. See also
[CentOS forum](https://www.centos.org/forums/viewtopic.php?t=21185).
