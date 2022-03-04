#!/bin/bash
# $Id: build.sh,v 1.5 2022/01/02 14:54:33 bob Exp $
# Build script for packaging latest build of Music Player Daemon Client (MPC)
# Run this script as user pi and not root

# Modify package definition with version number
# Amend this to point to the actual MPC build directory
BUILD_DIR=/home/pi/mpc-0.34

PKG=mpc
PKGDEF=mpcpkg
ARCH=$(grep ^Architecture: ${PKGDEF} | awk '{print $2}')
VERSION=$(grep ^Version: ${PKGDEF} | awk '{print $2}')
DEBPKG=${PKG}_${VERSION}_${ARCH}.deb
OS_RELEASE=/etc/os-release
DIR=~/mpc-${VERSION}

SAVEIFS=${IFS}; IFS='-'
VERSION=$(echo ${BUILD_DIR} | awk '{print $2}' | sed 's/"//g')
IFS=${SAVEIFS}
echo "Building MPC version ${VERSION}"
sed -i "s/^Version:.*/Version: ${VERSION}/" ${PKGDEF} 

# Check we are not running as sudo
if [[ "$EUID" -eq 0 ]];then
        echo "Run this script as user pi and not sudo/root"
        exit 1
fi

# Tar build for Rasbian Buster (Release 10) or later
VERSION_ID=$(grep VERSION_ID ${OS_RELEASE})
SAVEIFS=${IFS}; IFS='='
ID=$(echo ${VERSION_ID} | awk '{print $2}' | sed 's/"//g')
if [[ ${ID} -lt 10 ]]; then
        VERSION=$(grep VERSION= ${OS_RELEASE})
        echo "Raspbian Buster (Release 10) or later is required to run this build"
        RELEASE=$(echo ${VERSION} | awk '{print $2 $3}' | sed 's/"//g')
        echo "This is Raspbian ${RELEASE}"
        exit 1
fi
IFS=${SAVEIFS}

if [[ -d ${BUILD_DIR}/output ]]; then
	# Link the build directory 
	echo "Linking output directory to MPC build directory ${BUILD_DIR}/output"
	cmd="rm -rf output"
	echo ${cmd}; ${cmd}
	cmd="ln -s ${BUILD_DIR}/output"
	echo ${cmd}; ${cmd}
else
	echo "ERROR: ${BUILD_DIR}/output not found"
	echo "Check that BUILD_DIR is correctly specified in this script"
	echo "Aborting"
	exit 1
fi

# Copy compiled MPC binary and configurations files from the build directory
RELEASE=output
CONTRIB=contrib

# Copy compiled files 
pwd
echo
echo "Copying MPC files from ${BUILD_DIR}"
cmd="cp ${BUILD_DIR}/${RELEASE}/mpc ."
echo ${cmd}; ${cmd}
cmd="cp ${BUILD_DIR}/AUTHORS ."
echo ${cmd}; ${cmd}
cmd="cp ${BUILD_DIR}/COPYING ."
echo ${cmd}; ${cmd}
cmd="cp ${BUILD_DIR}/NEWS ."
echo ${cmd}; ${cmd}
cmd="cp ${BUILD_DIR}/README.rst ."
echo ${cmd}; ${cmd}
cmd="cp ${BUILD_DIR}/${CONTRIB}/mpd-m3u-handler.sh ."
echo ${cmd}; ${cmd}
cmd="cp ${BUILD_DIR}/${CONTRIB}/mpd-pls-handler.sh ."
echo ${cmd}; ${cmd}
cmd="cp ${BUILD_DIR}/${CONTRIB}/mpc-completion.bash ."
echo ${cmd}; ${cmd}

cmd="sudo apt-get -y install equivs apt-file lintian"
echo ${cmd}; ${cmd}

echo
echo "Building package ${PKG} version ${VERSION}"
echo "from input file ${PKGDEF}"

# Build the package
equivs-build ${PKGDEF}
echo ""
sudo apt autoremove

# List contents
echo ""
dpkg --contents  ${DEBPKG}

echo -n "Check using Lintian y/n: "
read ans
if [[ ${ans} == 'y' ]]; then
	echo "Checking package ${DEBPKG} with lintian"
	lintian ${DEBPKG}
	if [[ $? = 0 ]]
	then
	    dpkg -c ${DEBPKG}
	    echo "Package ${DEBPKG} OK"
	else
	    echo "Package ${DEBPKG} has errors"
	fi
fi

# End of build script

