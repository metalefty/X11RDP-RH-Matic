X11RDP-RH-Matic
===============

Install helper tool for xrdp/x11rdp


Usage
----
```
$ git clone https://github.com/metalefty/X11RDP-RH-Matic.git
$ cd X11RDP-RH-Matic
$ ./X11RDP-RH-Matic.sh
```

Supported Distributions
----

Currently, X11RDP-RH-Matic is developed on CentOS 6.5 and tested following
distributions. It may work on other RHEL clone distributions. Please report
if you confirmed it works.

- CentOS release 6.5 (Final)
- Scientific Linux release 6.5 (Carbon)


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
