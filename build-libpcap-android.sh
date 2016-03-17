#!/bin/bash

# --------------------------------------
#
# Title: build-libpcap-android
#
# Purpose: download & build libpcap for arm android platform
#
# You have to define your android NDK directory before calling this script
# example:
# $ export NDK=/home/Workspace/android-ndk-r10e
# $ sh build-libpcap-android <toolchain arch>
#
# --------------------------------------

# default, edit versions
libpcap_ver=1.7.4
android_api_def=21
ndk_dir_def=android-ndk-r10e

#-------------------------------------------------------#

libpcap_dir=libpcap-${libpcap_ver}


if [ ${NDK} ]
then
	ndk_dir=${NDK}
else
	ndk_dir=${ndk_dir_def}
fi

ndk_dir=`readlink -f ${ndk_dir}`

if [ ${ANDROID_API} ]
then
	android_api=${ANDROID_API}
else
	android_api=${android_api_def}
fi

echo "_______________________"
echo ""
echo "NDK - ${ndk_dir}"
echo "Android API: ${android_api}"
echo "_______________________"


exit_error()
{
	echo " _______"
	echo "|       |"
	echo "| ERROR |"
	echo "|_______|"
	exit 1
}

{
	if [ $# -ne 1 ]
	then
		echo Toolchain architecture not specified
		exit 1
	fi

	mkdir libpcapbuild
	cd libpcapbuild
}



# create env
{
	echo " ____________________"
	echo "|                    |"
	echo "| CREATING TOOLCHAIN |"
	echo "|____________________|"

	case "$1" in
		'armeabi')
			toolchain=arm-linux-androideabi-4.9
			export CC=arm-linux-androideabi-gcc
    		export CFLAGS="-fPIE -pie"
			export RANLIB=arm-linux-androideabi-ranlib
			export AR=arm-linux-androideabi-ar
			export LD=arm-linux-androideabi-ld
			export PATH=`pwd`/toolchain/bin:$PATH
			;;
		'armeabi-v7a')
			toolchain=arm-linux-androideabi-4.9
			export CC=arm-linux-androideabi-gcc
    		export CFLAGS="-fPIE -pie -march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3-d16"
    		export LDFLAGS="-march=armv7-a -Wl,--fix-cortex-a8"
			export RANLIB=arm-linux-androideabi-ranlib
			export AR=arm-linux-androideabi-ar
			export LD=arm-linux-androideabi-ld
			export PATH=`pwd`/toolchain/bin:$PATH
			;;
		'arm64-v8a')
			toolchain=aarch64-linux-android-4.9
			export CC=aarch64-linux-android-gcc
    		export CFLAGS="-fPIE -pie"
			export RANLIB=aarch64-linux-android-ranlib
			export AR=aarch64-linux-android-ar
			export LD=aarch64-linux-android-ld
			export PATH=`pwd`/toolchain/bin:$PATH
			;;
		*)
			echo "$1 not supported"
			exit 1
			;;
	esac

	echo Creating toolchain...
	rm -rf toolchain
	rm -rf $libpcap_dir

	mkdir toolchain
	bash ${ndk_dir}/build/tools/make-standalone-toolchain.sh --toolchain=${toolchain} --platform=android-${android_api} --install-dir=toolchain
}

# download & untar libpcap
{
	echo " _______________________________"
	echo "|                               |"
	echo "| DOWNLOADING LIBPCAP           |"
	echo "|_______________________________|"
	
	libpcap_file=${libpcap_dir}.tar.gz
	libpcap_link=http://www.tcpdump.org/release/${libpcap_file}
	
	if [ -f ${libpcap_file} ]
	then
		echo ${libpcap_file} already downloaded! Nothing to do.
	else
		echo Download ${libpcap_file}...
		wget ${libpcap_link}
		if [ ! -f ${libpcap_file} ]
		then
			exit_error
		fi
	fi
	
	if [ -d ${libpcap_dir} ]
	then
		echo ${libpcap_dir} directory already exist! Nothing to do.
	else
		echo untar ${libpcap_file}
		tar -zxf ${libpcap_file}
	fi
}

# build libpcap
{
	cd ${libpcap_dir}

	echo " _____________________"
	echo "|                     |"
	echo "| CONFIGURING LIBPCAP |"
	echo "|_____________________|"

	chmod +x configure
	./configure --host=arm-linux --with-pcap=linux

	if [ $? -ne 0 ]
	then
		exit_error
	fi	

	echo " __________________"
	echo "|                  |"
	echo "| BUILDING LIBPCAP |"
	echo "|__________________|"

	chmod +x runlex.sh
	make

	if [ $? -ne 0 ]
	then
		exit_error
	fi
}
