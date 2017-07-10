2.0.7
----
- Correct private key path during post-install certificate generation

2.0.6
-----
- Add script to run test in docker (for developers)
- Enable IPv6
- Fix libpainter/librfxcodec build on EL6
- Fix some branch/version calculation
- Obtain version from configure.ac not readme.txt
- Quit creating non-suid Xorg.xrdp as it no longer needed

2.0.5
-----
- Always use https to fetch source
- Add maintainer mode
- Fix the xrdp build on EL6
- Fix the x11rdp build (#39, #40)
- Rename xorg-x11-drv-xrdp to xorgxrdp
 - if you already have installed xorg-x11-drv-xrdp, uninstall before run RH-Matic
- Lots of cleanups, improbe build robustness

Thanks to
- Elio Coutinho
- Hiroki Takada

2.0.4
-----
- Fix the build failure not fixed in 2.0.3

2.0.3
-----
- Sanitize git branch name to use it in package name
- Fix dependencies
- Update patches to fit upstream

2.0.2
-----
- Default to use https to fetch source code
- `--with-xorg-driver` option is replaced with `--with-xorgxrdp`
- GitHub account/project/branch are now configurable by environment variable
- Improve build of librfxcodec, libpainter
- Fix the build on EL6
- other trivial fixes

Thanks to
- Pavel Roskin

2.0.1
-----
- Disable librfxcodec as it is still unstable
- Fix the build failure on EL6 (using EPEL)


2.0.0
-----
Lots of changes :p

- Support systemd
- Improve build robustness
- Improve support of xorgxrdp
- etc

`git diff v1.0.4..v2.0.0` to show all diffs since previous release.

A big thanks to all the contributors and especially
- Carsten Grohmann
- Kentaro Hayashi

1.0.4
-----
Fix the build failure if systemtap-sdt-devel is installed. [RHEL Bug 694552](https://bugzilla.redhat.com/show_bug.cgi?id=694552)

1.0.3
-----
Improve build robustness.

1.0.2
-----
Improve build robustness.

1.0.1
-----
Some build fixes for Fedora 20.

1.0.0
-----

First release.
