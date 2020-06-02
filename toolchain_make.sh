#!/bin/bash

# 脚本当前目录
SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )"
# 当前目录
PWD="$( pwd )"
# make install的安装路径
CONFIGURE_PREFIX=${PWD}/build
# 用户自定义configure参数
# CONFIGURE_USER_PARAM="--disable-sse"
CONFIGURE_USER_PARAM="--disable-processor --disable-tools"
# ANDROID工具链路径
ANDROID_TOOLCHAIN_PATH=/usr/local/Caskroom/android-ndk/21/android-ndk-r21/toolchains/llvm/prebuilt/darwin-x86_64
# Make的并发核数
MAKE_JOBS=8
# 用户自定义编译参数
USER_CFLAGS="-Wdeprecated-declarations"
USER_CXXFLAGS="-Wdeprecated-declarations"
# Configure BUILD参数
CONFIGURE_BUILD="x86_64-macosx"

function toolchain_build() {
	TOOLCHAIN_PLATFORM=$1
	TOOLCHAIN_CPU_ARCH=$2
	if [ "${TOOLCHAIN_PLATFORM}" == "android" ]; then
		if [ "${TOOLCHAIN_CPU_ARCH}" == "armv7a" ]; then
			TARGET=armv7a-linux-androideabi
			OTHER_TARGET=arm-linux-androideabi
			ANDROID_API=16
			CONFIGURE_HOST="${TARGET}"
		elif [ "${TOOLCHAIN_CPU_ARCH}" == "arm64" ]; then
			TARGET=aarch64-linux-android
			OTHER_TARGET=aarch64-linux-android
			ANDROID_API=21
			CONFIGURE_HOST="${TARGET}"
		elif [ "${TOOLCHAIN_CPU_ARCH}" == "x86" ]; then
			TARGET=i686-linux-android
			OTHER_TARGET=i686-linux-android
			ANDROID_API=16
			CONFIGURE_HOST="${TARGET}"
		elif [ "${TOOLCHAIN_CPU_ARCH}" == "x86_64" ]; then
			TARGET=x86_64-linux-android
			OTHER_TARGET=x86_64-linux-android
			ANDROID_API=21
			CONFIGURE_HOST="${TARGET}"
		else
			echo "工具链函数调用错误：CPU架构不兼容"
			exit 1
		fi

		HOST_FLAGS="-O3"

		export AR="$ANDROID_TOOLCHAIN_PATH"/bin/"${OTHER_TARGET}"-ar
		export AS="$ANDROID_TOOLCHAIN_PATH"/bin/"${OTHER_TARGET}"-as
		export NM="$ANDROID_TOOLCHAIN_PATH"/bin/"${OTHER_TARGET}"-nm
		export CC="$ANDROID_TOOLCHAIN_PATH"/bin/"${TARGET}""${ANDROID_API}"-clang
		export CXX="$ANDROID_TOOLCHAIN_PATH"/bin/"${TARGET}""${ANDROID_API}"-clang++
		export LD="$ANDROID_TOOLCHAIN_PATH"/bin/"${OTHER_TARGET}"-ld
		export RANLIB="$ANDROID_TOOLCHAIN_PATH"/bin/"${OTHER_TARGET}"-ranlib
		export STRIP="$ANDROID_TOOLCHAIN_PATH"/bin/"${OTHER_TARGET}"-strip
		export STRINGS="$ANDROID_TOOLCHAIN_PATH"/bin/"${OTHER_TARGET}"-strings
		export SYSROOT="$ANDROID_TOOLCHAIN_PATH"/sysroot
		export CFLAGS="${HOST_FLAGS} ${USER_CFLAGS} ${CFLAGS} --sysroot=${SYSROOT} -I${SYSROOT}/usr/include -fPIE -DANDROID"
		export CXXFLAGS="${HOST_FLAGS} ${USER_CXXFLAGS} ${CXXFLAGS} --sysroot=${SYSROOT} -I${SYSROOT}/usr/include -fPIE -DANDROID"
		export LDFLAGS="${HOST_FLAGS} ${LDFLAGS} -L${SYSROOT}/usr/lib"
	elif [ "${TOOLCHAIN_PLATFORM}" = "ios" ]; then
		MIN_IOS_VERSION=8.0
		if [ "${TOOLCHAIN_CPU_ARCH}" == "armv7a" ]; then
			IOS_SDK="iphoneos"
			ARCH_FLAGS="-arch armv7 -arch armv7s -miphoneos-version-min=${MIN_IOS_VERSION}"

			CONFIGURE_HOST="arm-apple-darwin"
		elif [ "${TOOLCHAIN_CPU_ARCH}" == "arm64" ]; then
			IOS_SDK="iphoneos"
			ARCH_FLAGS="-arch arm64 -arch arm64e -miphoneos-version-min=${MIN_IOS_VERSION}"
			CONFIGURE_HOST="arm-apple-darwin"
		elif [ "${TOOLCHAIN_CPU_ARCH}" == "x86" ]; then
			IOS_SDK="iphonesimulator"
			ARCH_FLAGS="-arch i386 -mios-simulator-version-min=${MIN_IOS_VERSION}"
			CONFIGURE_HOST="i386-apple-darwin"
		elif [ "${TOOLCHAIN_CPU_ARCH}" == "x86_64" ]; then
			IOS_SDK="iphonesimulator"
			ARCH_FLAGS="-arch x86_64 -mios-simulator-version-min=${MIN_IOS_VERSION}"
			CONFIGURE_HOST="x86_64-apple-darwin"
		else
			echo "工具链函数调用错误：CPU架构不兼容"
			exit 1
		fi

		HOST_FLAGS="${ARCH_FLAGS} -O3 -fembed-bitcode"

		export AR="$(xcrun --find --sdk "${IOS_SDK}" ar)"
		export AS="$(xcrun --find --sdk "${IOS_SDK}" as)"
		export NM="$(xcrun --find --sdk "${IOS_SDK}" nm)"
		export CC="$(xcrun --find --sdk "${IOS_SDK}" clang)"
		export CXX="$(xcrun --find --sdk "${IOS_SDK}" clang++)"
		export CPP="$(xcrun --find --sdk "${IOS_SDK}" cpp)"
		export LD="$(xcrun --find --sdk "${IOS_SDK}" ld)"
		export RANLIB="$(xcrun --find --sdk "${IOS_SDK}" ranlib)"
		export STRIP="$(xcrun --find --sdk "${IOS_SDK}" strip)"
		export STRINGS="$(xcrun --find --sdk "${IOS_SDK}" strings)"
		export SYSROOT=$(xcrun --sdk ${IOS_SDK} --show-sdk-path)

		export CFLAGS="${HOST_FLAGS} ${USER_CFLAGS} ${CFLAGS} --sysroot=${SYSROOT} -I${SYSROOT}/usr/include -fPIE"
		export CXXFLAGS="${HOST_FLAGS} ${USER_CXXFLAGS} ${CXXFLAGS} --sysroot=${SYSROOT} -I${SYSROOT}/usr/include -fPIE"
		export LDFLAGS="${HOST_FLAGS} ${LDFLAGS} -L${SYSROOT}/usr/lib"
		
	elif [ "${TOOLCHAIN_PLATFORM}" = "mac" ]; then
		MIN_MAC_VERSION=10.10
		if [ "${TOOLCHAIN_CPU_ARCH}" == "x86_64" ]; then
			MAC_SDK="macosx"
			ARCH_FLAGS="-arch x86_64 -mmacosx-version-min=${MIN_MAC_VERSION}"
			CONFIGURE_HOST="x86_64-macosx"
		else
			echo "工具链函数调用错误：CPU架构不兼容"
			exit 1
		fi

		HOST_FLAGS="${ARCH_FLAGS} -O3 -fembed-bitcode"

		export AR="$(xcrun --find --sdk "${MAC_SDK}" ar)"
		export AS="$(xcrun --find --sdk "${MAC_SDK}" as)"
		export NM="$(xcrun --find --sdk "${MAC_SDK}" nm)"
		export CC="$(xcrun --find --sdk "${MAC_SDK}" clang)"
		export CXX="$(xcrun --find --sdk "${MAC_SDK}" clang++)"
		export CPP="$(xcrun --find --sdk "${MAC_SDK}" cpp)"
		export LD="$(xcrun --find --sdk "${MAC_SDK}" ld)"
		export RANLIB="$(xcrun --find --sdk "${MAC_SDK}" ranlib)"
		export STRIP="$(xcrun --find --sdk "${MAC_SDK}" strip)"
		export STRINGS="$(xcrun --find --sdk "${MAC_SDK}" strings)"
		export SYSROOT=$(xcrun --sdk ${MAC_SDK} --show-sdk-path)

		export CFLAGS="${HOST_FLAGS} ${USER_CFLAGS} ${CFLAGS} --sysroot=${SYSROOT} -I${SYSROOT}/usr/include -fPIE"
		export CXXFLAGS="${HOST_FLAGS} ${USER_CXXFLAGS} ${CXXFLAGS} --sysroot=${SYSROOT} -I${SYSROOT}/usr/include -fPIE"
		export LDFLAGS="${HOST_FLAGS} ${LDFLAGS} -L${SYSROOT}/usr/lib"
	else
		echo "工具链函数调用错误：平台不兼容"
		exit 1
	fi
	echo "开始执行Configure"
	if ! ./configure -q --host="${CONFIGURE_HOST}" --build="${CONFIGURE_BUILD}" \
		${CONFIGURE_USER_PARAM} \
		--prefix="${CONFIGURE_PREFIX}"/"${TOOLCHAIN_PLATFORM}"/"${TOOLCHAIN_CPU_ARCH}"
	then
		echo "Configure运行失败，请检查脚本或者是否为autoconf项目"
		exit 1
	fi
	echo "开始执行Make clean"
	
	if ! make --silent clean 1>/dev/null
	then
		echo "Make clean运行失败，请检查Makefile是否正常生成"
		exit 1
	fi
	echo "开始执行Make"
	
	if ! make --silent V=1 -j"${MAKE_JOBS}" install 1>/dev/null
	then
		echo "Make运行失败，请检查代码错误"
		exit 1
	fi
}

function usage() {
	echo "usage: 脚本名 平台名 CPU架构名"
	echo "平台名可选：mac，android, ios"
	echo "CPU架构名可选：armv7a, arm64, x86, x86_64"
	exit 1
}

if [ $# -ne 2 ]; then
	echo "参数个数不对"
	usage
fi

#第一个参数是平台，目前支持mac、android和ios
PLATFORM=$1
#第二个参数是CPU架构，目前支持armv7a、arm64、x86、x86_64
CPU_ARCH=$2

# 平台名校验
if [ "${PLATFORM}" != "android" ] && [ "${PLATFORM}" != "ios" ] && [ "${PLATFORM}" != "mac" ]; then
	echo "平台名不准确"
	usage
fi

# CPU架构名校验
if [ "${CPU_ARCH}" != "armv7a" ] && [ "${CPU_ARCH}" != "arm64" ] && [ "${CPU_ARCH}" != "x86" ] && [ "${CPU_ARCH}" != "x86_64" ]; then
	echo "CPU架构名不准确"
	usage
fi

# 开始编译
toolchain_build "${PLATFORM}" "${CPU_ARCH}"
