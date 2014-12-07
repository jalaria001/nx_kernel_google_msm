#!/bin/bash

if [ ! -e /usr/bin/ccache ]; then
	echo "You must install 'ccache' to continue.";
	sudo apt-get install ccache
fi

export ARCH=arm;
export SUB_ARCH=arm;
export USER=`whoami`;
export TMPFILE=`mktemp -t`;
export KBUILD_BUILD_USER="anderson";
export KBUILD_BUILD_HOST="ubuntu";
export CROSS_COMPILE=./toolch/L4.9.1/bin/arm-eabi-;
export NUMBEROFCPUS=`grep 'processor' /proc/cpuinfo | wc -l`;
export red=$(tput setaf 1)  
export grn=$(tput setaf 2)
export blu=$(tput setaf 4)
export cya=$(tput setaf 6)
export txtbld=$(tput bold)
export bldred=${txtbld}$(tput setaf 1)
export bldgrn=${txtbld}$(tput setaf 2)
export bldblu=${txtbld}$(tput setaf 4)
export bldcya=${txtbld}$(tput setaf 6)
export txtrst=$(tput sgr0)
