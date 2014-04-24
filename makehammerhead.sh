#!/bin/bash

###############################################################################
# To all DEV around the world :)                                              #
# to build this kernel you need to be ROOT and to have bash as script loader  #
# do this:                                                                    #
# cd /bin                                                                     #
# rm -f sh                                                                    #
# ln -s bash sh                                                               #
# now go back to kernel folder and run:                                       # 
#                                                         		      #
# sh clean_kernel.sh                                                          #
#                                                                             #
# Now you can build my kernel.                                                #
# using bash will make your life easy. so it's best that way.                 #
# Have fun and update me if something nice can be added to my source.         #
###############################################################################

# Time of build startup
res1=$(date +%s.%N)

echo "${bldcya}***** Setting up Environment *****${txtrst}";

# CCache
export USE_CCACHE=1
export CCACHE_DIR=./tmp
export CCACHE_LOGFILE=./tmp/ccache.log

. ./setup.sh ${1} || exit 1;

config=n5x_defconfig

export KERNEL_CONFIG="$config";

# Generate Ramdisk
echo "${bldcya}***** Generating Ramdisk *****${txtrst}"
echo "0" > $TMPFILE;

(

	# remove previous initramfs files
	if [ -d $INITRAMFS_TMP ]; then
		echo "${bldcya}***** Removing old temp initramfs_source *****${txtrst}";
		rm -rf $INITRAMFS_TMP;
	fi;

	mkdir -p $INITRAMFS_TMP;
	cp -ax $INITRAMFS_SOURCE/* $INITRAMFS_TMP;
	# clear git repository from tmp-initramfs
	
	# clear mercurial repository from tmp-initramfs
	if [ -d $INITRAMFS_TMP/.hg ]; then
		rm -rf $INITRAMFS_TMP/.hg;
	fi;

	# remove empty directory placeholders from tmp-initramfs
	find $INITRAMFS_TMP -name EMPTY_DIRECTORY | parallel rm -rf {};

	# remove more from from tmp-initramfs ...
	rm -f $INITRAMFS_TMP/update* >> /dev/null;

	./utilities/mkbootfs $INITRAMFS_TMP | gzip > ramdisk.gz

	echo "1" > $TMPFILE;
	echo "${bldcya}***** Ramdisk Generation Completed Successfully *****${txtrst}"
)&

if [ ! -f $KERNELDIR/.config ]; then
	echo "${bldcya}***** Clean Build Initiating *****${txtrst}";
	cp $KERNELDIR/arch/arm/configs/$KERNEL_CONFIG .config;
	make $KERNEL_CONFIG;
else
	echo "${bldcya}***** Dirty Build Initiating *****${txtrst}";	
fi;

. $KERNELDIR/.config
echo "${bldcya}Building => Kernel";

# remove previous zImage files
if [ -e $KERNELDIR/out/zImage ]; then
	rm $KERNELDIR/out/zImage;
	rm $KERNELDIR/out/boot.img;
fi;
if [ -e $KERNELDIR/arch/arm/boot/zImage ]; then
	rm $KERNELDIR/arch/arm/boot/zImage;
fi;

# remove previous initramfs files
rm -rf $KERNELDIR/out/temp >> /dev/null;

# clean initramfs old compile data
rm -f $KERNELDIR/usr/initramfs_data.cpio >> /dev/null;
rm -f $KERNELDIR/usr/initramfs_data.o >> /dev/null;

# wait for the successful ramdisk generation
while [ $(cat ${TMPFILE}) == 0 ]; do
	echo "${bldblu}Waiting for Ramdisk generation completion.${txtrst}";
	sleep 2;
done;

# make zImage
echo "${bldcya}***** Compiling kernel *****${txtrst}"
if [ $USER != "root" ]; then
	make -j$NUMBEROFCPUS CONFIG_NO_ERROR_ON_MISMATCH=y zImage-dtb
else
	nice -n -15 make -j$NUMBEROFCPUS CONFIG_NO_ERROR_ON_MISMATCH=y zImage-dtb
fi;

if [ -e $KERNELDIR/arch/arm/boot/zImage ]; then
        echo "${bldcya}***** Final Touch for Kernel *****${txtrst}"
	rm $KERNELDIR/out/zImage >> /dev/null;
        cp $KERNELDIR/arch/arm/boot/zImage-dtb $KERNELDIR/out/zImage;
        stat $KERNELDIR/out/zImage || exit 1;
	
	echo "--- Creating boot.img ---"
	# copy all needed to out kernel folder
        ./utilities/mkbootimg --kernel $KERNELDIR/out/zImage --cmdline 'console=ttyHSL0,115200,n8 androidboot.hardware=hammerhead user_debug=31 msm_watchdog_v2.enable=1' --base 0x00000000 --pagesize 2048 --ramdisk_offset 0x02900000 --tags_offset 0x02700000 --ramdisk ramdisk.gz --output $KERNELDIR/out/boot.img
        echo "${bldcya}***** Flashing boot.img ******${txtrst}";
	fastboot flash boot $KERNELDIR/out/boot.img
	echo "${bldcya}***** All done! *****${txtrst}";
	# finished? get elapsed time
	res2=$(date +%s.%N)
	echo "${bldgrn}Total time elapsed: ${txtrst}${grn}$(echo "($res2 - $res1) / 60"|bc ) minutes ($(echo "$res2 - $res1"|bc ) seconds) ${txtrst}";	
else
	echo "${bldred}Kernel STUCK in BUILD!${txtrst}"
fi;

