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

Supported Distributions (confirmed)
----

Currently, X11RDP-RH-Matic is developed on CentOS 7 and tested following
distributions. It may work on other RHEL clone distribution such as Oracle Linux.
Please report if you confirmed it works.

- Red Hat Enterprise Linux Server release 7.2 (Maipo)
- CentOS release 6.5 (Final)
- CentOS release 6.6 (Final) reported by Michael Niehren
- CentOS Linux release 7.2.1511 (Core)
- Scientific Linux release 6.5 (Carbon)
- Asianux Server release 7 SP1 (Lotus)

Support policy
---
X11RDP-RH-Matic supports the latest major version and one previous version of RHEL and its clones.
That is 7.x and 6.x as of June 13, 2016.


TODOs
----

- Build PulseAudio module

Building xorgxrdp (formerly known as xorg-driver)
----
X11RDP-RH-Matic can build xorgxrdp (aka xorg-driver). Run with `--with-xorg-driver`
option. When you want to build xorgxrdp, probably you don't need X11rdp then also
add `--nox11rdp` option.

```
$ ./X11RDP-RH-Matic.sh --with-xorg-driver --nox11rdp
```

Now RH-Matic installs non-suid version of Xorg to `/usr/bin/Xorg.xrdp`.
You don't need to edit `/etc/pam.d/xserver` introduced in
[CentOS forum](https://www.centos.org/forums/viewtopic.php?t=21185).

Contributing
----

First off, thanks for taking your time for improve X11RDP-RH-Matic.

If you contribute to X11RDP-RH-Matic, checkout develop branch and make changes to the branch.
Please make pull requests also versus develop branch.
