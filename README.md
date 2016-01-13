X11RDP-RH-Matic
===============

What is this?
----
X11RDP-RH-Matic helps to build and install latest snapshot of [xrdp](https://github.com/neutrinolabs/xrdp), x11rdp, xorgxrdp (xorg-driver) for Red Hat Enterprise Linux or its clones.

This utility is inspired by [X11RDP-o-Matic](https://github.com/scarygliders/X11RDP-o-Matic). In other words, Red Hat version of X11RDP-o-Matic.

What this is not?
----
- xrdp itself
- for all Red Hat "based" Linux

X11RDP-RH-Matic only supports RHEL or its clones. If you can use yum(or dnf)/rpm in
your distribution, your distribution is not necessarily supprted.

Usage
----
```
$ git clone https://github.com/metalefty/X11RDP-RH-Matic.git
$ cd X11RDP-RH-Matic
$ ./X11RDP-RH-Matic.sh
```

Use develop branch to try development snapshot.

Supported Distributions
----

Currently, X11RDP-RH-Matic is developed on CentOS 7 and tested following
distributions. It may work on other RHEL clone distribution such as Oracle Linux.
Please report if you confirmed it works.

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
