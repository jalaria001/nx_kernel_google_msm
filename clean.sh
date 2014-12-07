#!/bin/bash

. ./env_setup.sh ${1} || exit 1;

echo "${bldcya}***** Cleaning in Progress *****${txtrst}";

make mrproper 					>> /dev/null
make clean 						>> /dev/null
rm -f arch/arm/boot/zImage-dtb 	>> /dev/null
rm -f r*.cpio 					>> /dev/null
rm -rf include/generated 		>> /dev/null
rm -rf arch/*/include/generated >> /dev/null
rm -f $RAMDISKDIR/zImage* 		>> /dev/null
rm -f boot.img 					>> /dev/null
rm -f zip/boot.img 				>> /dev/null
rm -f zip/CharizardX 			>> /dev/null

echo "${bldcya}***** Cleaning Done *****${txtrst}";