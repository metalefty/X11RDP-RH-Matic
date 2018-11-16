X11RDP-RH-Matic  [![Build Status](https://travis-ci.org/metalefty/X11RDP-RH-Matic.svg?branch=develop)](https://travis-ci.org/metalefty/X11RDP-RH-Matic)
===============

What is this?
----
X11RDP-RH-Matic helps to build and install latest snapshot of [xrdp](https://github.com/neutrinolabs/xrdp), xorgxrdp (xorg-driver) for Red Hat Enterprise Linux or its clones.

This utility is inspired by [X11RDP-o-Matic](https://github.com/scarygliders/X11RDP-o-Matic). In other words, Red Hat version of X11RDP-o-Matic.

Please note this utility is oriented to xrdp developers or xrdp early testers.

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

Adding these options is recommended now.

```
$ ./X11RDP-RH-Matic.sh --with-xorg-driver
```

Use develop branch to try development snapshot.

X11RDP-RH-Matic uses official neutrinolabs repository by default.
If you want to build your own fork or other repository,
you can override GitHub account, repository and branch via environment variable.

```
$ GH_ACCOUNT=metalefty ./X11RDP-RH-Matic.sh # uses https://github.com/metalefty/xrdp.git
$ GH_BRANCH=devel ./X11RDP-RH-Matic.sh      # equivalent to ./X11RDP-RH-Matic.sh --branch devel
```

Supported Distributions (confirmed)
----

Currently, X11RDP-RH-Matic is developed on CentOS 7 and tested following
distributions. It may work on other RHEL clone distribution such as Oracle Linux.
Please report if you confirmed it works.

- Red Hat Enterprise Linux Server release 7.2 (Maipo)
- CentOS Linux release 7.2.1511 (Core)
- CentOS Linux release 7.3.1611 (Core)
- Asianux Server release 7 SP1 (Lotus)

Support policy
---
X11RDP-RH-Matic supports the latest major version and one previous version of RHEL and its clones.

CentOS 7.0 and 7.1 is not supported due to TLSv1.2 or higher being required by GitHub.


TODOs
----

- Build PulseAudio module

Building xorgxrdp (formerly known as xorg-driver)
----
X11RDP-RH-Matic can build xorgxrdp (aka xorg-driver). Run with `--with-xorg-driver`
option. When you want to build xorgxrdp.

```
$ ./X11RDP-RH-Matic.sh --with-xorgxrdp
```

Contributing
----

First off, thanks for taking your time for improve X11RDP-RH-Matic.

If you contribute to X11RDP-RH-Matic, checkout develop branch and make changes to the branch.
Please make pull requests also versus develop branch.

Development
----

To test X11RDP-RH-Matic, you can quickly prepare test environment using docker.

~~~
docker-host$ sudo docker pull centos:latest
docker-host$ sudo docker run --rm --interactive --tty centos:latest /bin/bash
docker-guest# adduser centos
docker-guest# usermod -G wheel centos
docker-guest# yum install -y sudo git
docker-guest# sudo -i -u centos
docker-guest$ git clone --branch develop https://github.com/metalefty/X11RDP-RH-Matic.git
~~~
