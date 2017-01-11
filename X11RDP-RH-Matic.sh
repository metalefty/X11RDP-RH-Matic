#!/bin/bash
#set -u # error unbound variables
# vim:ts=2:sw=2:sts=0:number
VERSION=2.0.1
RELEASEDATE=20160916

trap user_interrupt_exit 2

if [ $UID -eq 0 ] ; then
	# write to stderr 1>&2
	echo "${0}:  Never run this utility as root." 1>&2
	echo 1>&2
	echo "This utility builds RPMs. Building RPM's as root is seriously dangerous." 1>&2
	echo "This script will gain root privileges via sudo on demand, then type your password." 1>&2
	exit 1
fi

if ! hash sudo 2> /dev/null ; then
	# write to stderr 1>&2
	echo "${0}: sudo not found." 1>&2
	echo 1>&2
	echo 'This utility requires sudo to gain root privileges on demand.' 1>&2
	echo 'run `yum -y install sudo` in root privileges before run this utility.' 1>&2
	exit 1
fi

LINE="----------------------------------------------------------------------"

PATH=/bin:/sbin:/usr/bin:/usr/sbin

# xrdp repository
: ${GH_ACCOUNT:=neutrinolabs}
: ${GH_PROJECT:=xrdp}
: ${GH_BRANCH:=master}
GH_URL=https://github.com/${GH_ACCOUNT}/${GH_PROJECT}.git
# xorgxrdp repository
: ${GH_ACCOUNT_xorgxrdp:=neutrinolabs}
: ${GH_PROJECT_xorgxrdp:=xorgxrdp}
: ${GH_BRANCH_xorgxrdp:=master}
GH_URL_xorgxrdp=https://github.com/${GH_ACCOUNT_xorgxrdp}/${GH_PROJECT_xorgxrdp}.git


OLDWRKDIR=''
WRKDIR=$(mktemp --directory --suffix .X11RDP-RH-Matic)
YUM_LOG=${WRKDIR}/yum.log
BUILD_LOG=${WRKDIR}/build.log
SUDO_LOG=${WRKDIR}/sudo.log
RPMS_DIR=$(rpm --eval %{_rpmdir}/%{_arch})
SOURCE_DIR=$(rpm --eval %{_sourcedir})

# variables for this utility
TARGETS="xrdp x11rdp"
META_DEPENDS="rpm-build rpmdevtools"
FETCH_DEPENDS="ca-certificates git wget"
EXTRA_SOURCE="xrdp.init xrdp.sysconfig xrdp.logrotate"
XRDP_CONFIGURE_ARGS="--enable-fuse --enable-jpeg --disable-static"

# flags
PARALLELMAKE=true   # increase make jobs
INSTALL_XRDP=true   # install built package after build
MAINTAINER=false    # maintainer mode
IS_EL6=$([ "$(rpm --eval %{?rhel})" -le 6 ] && echo true || echo false)

# substitutes
XORGXRDPDEBUG_SUB="# "

# xrdp dependencies
XRDP_BASIC_BUILD_DEPENDS=$(<SPECS/xrdp.spec.in grep BuildRequires: | grep -v %% | awk '{ print $2 }' | tr '\n' ' ')
XRDP_ADDITIONAL_BUILD_DEPENDS="libjpeg-turbo-devel fuse-devel"
# xorg driver build dependencies
XORGXRDP_BUILD_DEPENDS=$(<SPECS/xorgxrdp.spec.in grep BuildRequires: | grep -v %% | awk '{ print $2 }' | tr '\n' ' ')
# x11rdp
X11RDP_BUILD_DEPENDS=$(<SPECS/x11rdp.spec.in grep BuildRequires: | awk '{ print $2 }' | tr '\n' ' ')

SUDO_CMD()
{
	# sudo's password prompt timeouts 5 minutes by most default settings
	# to avoid exit this script because of sudo timeout
	echo_stderr
	# not using echo_stderr here because output also be written $SUDO_LOG
	echo "Following command will be executed via sudo:" | tee -a $SUDO_LOG 1>&2
	echo "	$@" | tee -a $SUDO_LOG 1>&2
	while ! sudo -v; do :; done
	sudo $@ | tee -a $SUDO_LOG
	return ${PIPESTATUS[0]}
}

echo_stderr()
{
	echo $@ 1>&2
}

error_exit()
{
	echo_stderr; echo_stderr
	echo_stderr "Oops, something going wrong around line: $BASH_LINENO"
	echo_stderr "See logs to get further information:"
	echo_stderr "	$BUILD_LOG"
	echo_stderr "	$SUDO_LOG"
	echo_stderr "	$YUM_LOG"
	echo_stderr "Exiting..."
	if ${MAINTAINER}; then
		echo_stderr
		echo_stderr 'Maintainer mode detected, showing build log...'
		echo_stderr
		tail -n 100 ${BUILD_LOG} 1>&2
		echo_stderr
	fi
	[ -f .PID ] && [ "$(cat .PID)" = $$ ] && rm -f .PID
	exit 1
}

clean_exit()
{
	[ -f .PID ] && [ "$(cat .PID)" = $$ ] && rm -f .PID
	exit 0
}

user_interrupt_exit()
{
	echo_stderr; echo_stderr
	echo_stderr "Script stopped due to user interrupt, exiting..."
	[ -f .PID ] && [ "$(cat .PID)" = $$ ] && rm -f .PID
	exit 1
}

install_depends()
{
	for f in $@; do
		echo -n "Checking for ${f}... "
		check_if_installed $f
		if [ $? -eq 0 ]; then
			echo "yes"
		else
			echo "no"
			echo -n "Installing $f... "
			SUDO_CMD yum -y install $f >> $YUM_LOG && echo "done" || error_exit
		fi
		sleep 0.1
	done
}

check_if_installed()
{
	if [ "$(repoquery --all --installed --qf="%{name}" "$1")" = "$1" ]; then
		return 0
	else
		return 1
	fi
}

calculate_version_num()
{
	echo -n 'Calculating RPM version number... '

	XRDPVER=$(cd ${WRKDIR}/${WRKSRC}; grep xrdp readme.txt | head -1 | cut -d " " -f2)
	XORGXRDPVER=$(cd ${WRKDIR}/${WRKSRC_xorgxrdp}; grep "Current Version" README.md | head -1 | cut -d " " -f3)
	XRDPVER=${XRDPVER}.git${GH_COMMIT}
	XORGXRDPVER=${XORGXRDPVER}.git$(cd ${WRKDIR}/${WRKSRC_xorgxrdp}; git rev-parse HEAD | head -c7)

	echo xrdp=$XRDPVER xorgxrdp=$XORGXRDPVER
}

generate_spec()
{
	calculate_version_num
	calc_cpu_cores
	echo -n 'Generating RPM spec files... '

	GH_BRANCH_IN_PKGNAME=$(echo ${GH_BRANCH} |  sed -e 's|[^A-Za-z0-9._\+]|_|g')
	GH_BRANCH_IN_PKGNAME_xorgxrdp=$(echo ${GH_BRANCH_xorgxrdp} |  sed -e 's|[^A-Za-z0-9._\+]|_|g')

	# replace common variables in spec templates
	for f in SPECS/*.spec.in
	do
		sed \
		-e "s/%%XRDPVER%%/${XRDPVER}/g" \
		-e "s/%%XORGXRDPVER%%/${XORGXRDPVER}/g" \
		-e "s/%%XRDPBRANCH%%/${GH_BRANCH_IN_PKGNAME}/g" \
		-e "s/%%XORGXRDPBRANCH%%/${GH_BRANCH_IN_PKGNAME_xorgxrdp}/g" \
		-e "s/%%GH_ACCOUNT%%/${GH_ACCOUNT}/g" \
		-e "s/%%GH_PROJECT%%/${GH_PROJECT}/g" \
		-e "s/%%GH_COMMIT%%/${GH_COMMIT}/g" \
		-e "s/%%GH_ACCOUNT_xorgxrdp%%/${GH_ACCOUNT_xorgxrdp}/g" \
		-e "s/%%GH_PROJECT_xorgxrdp%%/${GH_PROJECT_xorgxrdp}/g" \
		-e "s/%%GH_COMMIT_xorgxrdp%%/${GH_COMMIT_xorgxrdp}/g" \
		< $f > ${WRKDIR}/$(basename ${f%.in}) || error_exit
	done

	sed -i.bak \
	-e "s/%%BUILDREQUIRES%%/${XORGXRDP_BUILD_DEPENDS}/g" \
	-e "s/%%XORGXRDPDEBUG%%/${XORGXRDPDEBUG_SUB}/g" \
	${WRKDIR}/xorgxrdp.spec || error_exit

	sed -i.bak \
	-e "s/%%BUILDREQUIRES%%/${XRDP_ADDITIONAL_BUILD_DEPENDS}/g" \
	-e "s/%%CONFIGURE_ARGS%%/${XRDP_CONFIGURE_ARGS}/g" \
	${WRKDIR}/xrdp.spec || error_exit

	sed -i.bak \
	-e "s|%%X11RDPBASE%%|/opt/X11rdp|g" \
	-e "s|make -j1|${makeCommand}|g" \
	${WRKDIR}/x11rdp.spec || error_exit

	if $IS_EL6; then
		sed -i.bak \
		-e 's|\(^BuildRequires:\s*\)\(autoconf\)|\1autoconf268|' \
		${WRKDIR}/xrdp.spec || error_exit
	fi

	echo 'done'
}

clone()
{
	GH_COMMIT=$(git ls-remote --heads $GH_URL | grep ${GH_BRANCH}$ | head -c7)
	WRKSRC=${GH_ACCOUNT}-${GH_PROJECT}-${GH_COMMIT}
	DISTFILE=${WRKSRC}.tar.gz
	echo -n 'Cloning xrdp source code... '

	if [ ! -f ${SOURCE_DIR}/${DISTFILE} ]; then
		# always clone via https
		git clone ${GH_URL} --branch ${GH_BRANCH} ${WRKDIR}/${WRKSRC} >> $BUILD_LOG 2>&1 || error_exit
		sed -i -e 's|git://|https://|' ${WRKDIR}/${WRKSRC}/.gitmodules ${WRKDIR}/${WRKSRC}/.git/config
		(cd ${WRKDIR}/${WRKSRC} && git submodule update --init --recursive)  >> $BUILD_LOG 2>&1

		if $IS_EL6; then
			sed -i -e 's|autoreconf|autoreconf268|' ${WRKDIR}/${WRKSRC}/bootstrap
		fi


		tar cfz ${WRKDIR}/${DISTFILE} -C ${WRKDIR} ${WRKSRC} || error_exit
		cp -a ${WRKDIR}/${DISTFILE} ${SOURCE_DIR}/${DISTFILE} || error_exit

		echo 'done'
	else
		echo 'already exists'
		echo -n 'Unpacking previously cloned source code... '
		tar zxf ${SOURCE_DIR}/${DISTFILE} -C ${WRKDIR} || error_exit
		echo 'done'
	fi

	# xorgxrdp
	GH_COMMIT_xorgxrdp=$(git ls-remote --heads $GH_URL_xorgxrdp | grep ${GH_BRANCH_xorgxrdp}$ | head -c7)
	WRKSRC_xorgxrdp=${GH_ACCOUNT_xorgxrdp}-${GH_PROJECT_xorgxrdp}-${GH_COMMIT_xorgxrdp}
	DISTFILE_xorgxrdp=${WRKSRC_xorgxrdp}.tar.gz
	echo -n 'Cloning xorgxrdp source code... '

  if [ ! -f ${SOURCE_DIR}/${DISTFILE_xorgxrdp} ]; then
		git clone ${GH_URL_xorgxrdp} --branch ${GH_BRANCH_xorgxrdp} ${WRKDIR}/${WRKSRC_xorgxrdp} >> $BUILD_LOG 2>&1 || error_exit

		if $IS_EL6; then
			sed -i -e 's|autoreconf|autoreconf268|' ${WRKDIR}/${WRKSRC_xorgxrdp}/bootstrap
		fi

		tar cfz ${WRKDIR}/${DISTFILE_xorgxrdp} -C ${WRKDIR} ${WRKSRC_xorgxrdp} || error_exit
		cp -a ${WRKDIR}/${DISTFILE_xorgxrdp} ${SOURCE_DIR}/${DISTFILE_xorgxrdp} || error_exit

		echo 'done'
	else
		echo 'already exists'
		echo -n 'Unpacking previously cloned source code... '
		tar zxf ${SOURCE_DIR}/${DISTFILE_xorgxrdp} -C ${WRKDIR} || error_exit
		echo 'done'
	fi
}

x11rdp_dirty_build()
{
	X11RDPBASE=/opt/X11rdp

	# remove installed x11rdp before build x11rdp
	check_if_installed x11rdp
	if [ $? -eq 0 ]; then
		SUDO_CMD yum -y remove x11rdp >> $YUM_LOG || error_exit
	fi

	# clean /opt/X11rdp
	if [ -d $X11RDPBASE ]; then
		SUDO_CMD find $X11RDPBASE -delete
	fi

	# extract xrdp source
	tar zxf ${SOURCE_DIR}/${DISTFILE} -C $WRKDIR || error_exit

	# build x11rdp once into $X11RDPBASE
	(
	cd ${WRKDIR}/${WRKSRC}/xorg/X11R7.6 && \
	sed -i.bak \
		-e 's/if ! mkdir $PREFIX_DIR/if ! mkdir -p $PREFIX_DIR/' \
		-e 's/wget -cq/wget -cq --retry-connrefused --waitretry=10/' \
		-e "s/make -j 1/make -j $jobs/g" \
		-e 's|^download_url=http://server1.xrdp.org/xrdp/X11R7.6|download_url=https://xrdp.vmeta.jp/pub/xrdp/X11R7.6|' \
		buildx.sh >> $BUILD_LOG 2>&1 && \
	SUDO_CMD ./buildx.sh $X11RDPBASE >> $BUILD_LOG 2>&1
	) || error_exit

	QA_RPATHS=$[0x0001|0x0002] rpmbuild -ba ${WRKDIR}/x11rdp.spec >> $BUILD_LOG 2>&1 || error_exit

	# cleanup installed files during the build
	if [ -d $X11RDPBASE ]; then
		SUDO_CMD find $X11RDPBASE -delete
	fi
}

rpmdev_setuptree()
{
	echo -n 'Setting up rpmbuild tree... '
	rpmdev-setuptree && \
	echo 'done'
}

build_rpm()
{
	echo 'Building RPMs started, please be patient... '
	echo 'Do the following command to see build progress.'
	echo "	$ tail -f $BUILD_LOG"
	for f in $EXTRA_SOURCE; do
		cp SOURCES/${f} $SOURCE_DIR
	done

	for f in $TARGETS; do
		echo -n "Building ${f}... "
		case "${f}" in
			xrdp) QA_RPATHS=$[0x0001] rpmbuild -ba ${WRKDIR}/${f}.spec >> $BUILD_LOG 2>&1 || error_exit ;;
			x11rdp) x11rdp_dirty_build || error_exit ;;
			*) rpmbuild -ba ${WRKDIR}/${f}.spec >> $BUILD_LOG 2>&1 || error_exit ;;
		esac
		echo 'done'
	done

	echo "Built RPMs are located in $RPMS_DIR."
}

parse_commandline_args()
{
	# If first switch = --help, display the help/usage message then exit.
	if [ "$1" = "--help" ]
	then
		echo "usage: $0 OPTIONS
OPTIONS
-------
  --help             : show this help.
  --version          : show version.
  --branch <branch>  : use one of the available xrdp branches listed above...
                       Examples:
                       --branch v0.8    - use the 0.8 branch.
                       --branch master  - use the master branch. <-- Default if no --branch switch used.
                       --branch devel   - use the devel branch (Bleeding Edge - may not work properly!)
                       Branches beginning with \"v\" are stable releases.
                       The master branch changes when xrdp authors merge changes from the devel branch.
  --nocpuoptimize    : do not change X11rdp build script to utilize more than 1 of your CPU cores.
  --cleanup          : remove X11rdp / xrdp source code after installation. (Default is to keep it).
  --maintainer       : maintainer mode
  --noinstall        : do not install anything, just build the packages
  --nox11rdp         : do not build and install x11rdp
  --with-xorgxrdp    : build xorgxrdp (formerly known as xorg-driver)
  --with-xorg-driver : alias for --with-xorgxrdp
  --xorgxrdpdebug    : increase log level of xorgxrdp
  --tmpdir <dir>     : specify working directory prefix (/tmp is default)"
		get_branches
		rmdir ${WRKDIR}
		exit 0
	fi

	while [ $# -gt 0 ]; do
		case "$1" in
		--version)
			show_version
		;;

		--branch)
			get_branches
			if [ $(expr "$BRANCHES" : ".*${2}.*") -ne 0 ]; then
				GH_BRANCH=$2
				GH_BRANCH_xorgxrdp=$2
			else
				echo "**** Error detected in branch selection. Argument after --branch was : $2 ."
				echo "**** Available branches : "$BRANCHES
				exit 1
			fi
			echo "Using branch ==>> $GH_BRANCH <<=="
			if [ $GH_BRANCH = 'devel' ]; then
				echo "Note : using the bleeding-edge version may result in problems :)"
			fi
			echo $LINE
			;;

		--maintainer)
			MAINTAINER=true
			;;

		--noinstall)
			INSTALL_XRDP=false
			;;

		--nocpuoptimize)
			PARALLELMAKE=false
			;;

		--nox11rdp)
			TARGETS=${TARGETS//x11rdp/}
			;;

		--with-xorg-driver) # alias for --with-xorgxrdp
			echo_stderr 'WARNING: --with-xorg-driver was renamed to --with-xorgxrdp'
			TARGETS="$TARGETS xorgxrdp"
			;;

		--with-xorgxrdp)
			TARGETS="$TARGETS xorgxrdp"
			;;

		--xorgxrdpdebug)
			XORGXRDPDEBUG_SUB=""
			;;

		--tmpdir)
			if [ ! -d "${2}" ]; then
			 	echo_stderr "Invalid working directory '${2}' specified."
				exit 1
			fi
			OLDWRKDIR=${WRKDIR}
			WRKDIR=$(mktemp --directory --suffix .X11RDP-RH-Matic --tmpdir="${2}") || exit 1
			YUM_LOG=${WRKDIR}/yum.log
			BUILD_LOG=${WRKDIR}/build.log
			SUDO_LOG=${WRKDIR}/sudo.log
			rmdir "${OLDWRKDIR}" || error_exit
			;;
		esac
		shift
	done
}

show_version()
{
	echo "X11RDP-RH-Matic $VERSION $RELEASEDATE"
	[ -f .PID ] && [ "$(cat .PID)" = $$ ] && rm -f .PID
	exit 0
}

get_branches()
{
	echo $LINE
	echo "Obtaining list of available branches..."
	echo $LINE
	BRANCHES=$(git ls-remote --heads $GH_URL | cut -f2 | cut -d "/" -f 3)
	echo $BRANCHES
	echo $LINE
}

calc_cpu_cores()
{
	jobs=$(($(nproc) + 1))
	if $PARALLELMAKE; then
		makeCommand="make -j $jobs"
	else
		makeCommand="make -j 1"
	fi
}

remove_installed_xrdp()
{
	$INSTALL_XRDP || return

	# uninstall xrdp first if installed
	for f in $TARGETS ; do
		echo -n "Removing installed $f... "
			check_if_installed $f
			if [ $? -eq 0 ]; then
				SUDO_CMD yum -y remove $f >>  $YUM_LOG || error_exit
			fi
		echo "done"
	done
}

install_built_xrdp()
{
	$INSTALL_XRDP || return

	for t in $TARGETS ; do
		echo -n "Installing built $t... "
		case "$t" in
			xorgxrdp)
				RPM_VERSION_SUFFIX=$(rpm --eval -${XORGXRDPVER}+${GH_BRANCH_IN_PKGNAME}-1%{?dist}.%{_arch}.rpm) ;;
			*)
				RPM_VERSION_SUFFIX=$(rpm --eval -${XRDPVER}+${GH_BRANCH_IN_PKGNAME}-1%{?dist}.%{_arch}.rpm) ;;
		esac
		SUDO_CMD yum -y localinstall \
			${RPMS_DIR}/${t}${RPM_VERSION_SUFFIX} \
			>> $YUM_LOG && echo "done" || error_exit
	done
}

install_targets_depends()
{
	for t in $TARGETS; do
		case "$t" in
			xrdp) install_depends $XRDP_BASIC_BUILD_DEPENDS $XRDP_ADDITIONAL_BUILD_DEPENDS;;
			x11rdp) install_depends $X11RDP_BUILD_DEPENDS ;;
			xorgxrdp) install_depends $XORGXRDP_BUILD_DEPENDS;;
		esac
	done
}

first_of_all()
{
	if [ ! -f X11RDP-RH-Matic.sh ]; then
		echo_stderr "Make sure you are in X11RDP-RH-Matic directory." 2>&1
		error_exit
	fi

	if [ -f .PID ]; then
		echo_stderr "Another instance of $0 is already running." 2>&1
		error_exit
	else
		echo $$ > .PID
	fi

	if [ -n "${OLDWRKDIR}" ]; then
		echo "Using working directory ${WRKDIR} instead of default."
	fi

	echo 'Allow X11RDP-RH-Matic to gain root privileges.'
	echo 'Type your password if required.'
	sudo -v

	# first of all, check if yum-utils installed
	echo 'First of all, checking for necessary programs to run this script... '
	echo -n 'Checking for yum-utils... '
	if hash repoquery 2> /dev/null; then
		echo 'yes'
	else
		echo 'no'
		echo -n 'Installing yum-utils... '
		SUDO_CMD yum -y install yum-utils >> $YUM_LOG && echo "done" || exit 1
	fi

	if $IS_EL6; then
		check_if_installed epel-release
		if [ $? -ne 0 ]; then
			echo "You are using $(cat /etc/redhat-release)."
			echo '"epel-release" is needed to run this script.'
			echo -n 'Installing epel-release...'
			SUDO_CMD yum -y install epel-release >> $YUM_LOG && echo 'done' || exit 1
		fi
		XRDP_BASIC_BUILD_DEPENDS=${XRDP_BASIC_BUILD_DEPENDS/autoconf /autoconf268 }
	fi
}

#
#  main routines
#

parse_commandline_args $@
first_of_all
install_depends $META_DEPENDS $FETCH_DEPENDS
rpmdev_setuptree
clone
generate_spec
install_targets_depends
build_rpm
remove_installed_xrdp
install_built_xrdp
echo; echo 'Everything is done!'
clean_exit
