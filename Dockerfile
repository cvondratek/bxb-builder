FROM ubuntu:18.04

ARG ARM_GCC=gcc-arm-8.3-2019.03-x86_64-arm-linux-gnueabihf

#override/set these with:
#docker build --build-arg HTTPPROXY=$http_proxy --build-arg HTTPSPROXY=$https_proxy --build-arg NOPROXY=$no_proxy 
ARG HTTPPROXY=
ARG HTTPSPROXY=
#if you have a proxy, no proxy is required for entrypoint.sh to access the jenkins cli
ARG NOPROXY=http://127.0.0.1*,http://localhost*

#xfr args to env vars... these only affect the running container.
#docker daemon needs it's own proxy config for pulls, etc.
ENV no_proxy=$NOPROXY
ENV http_proxy=$HTTPPROXY
ENV https_proxy=$HTTPSPROXY
ENV NO_PROXY=$NOPROXY
ENV HTTP_PROXY=$HTTPPROXY
ENV HTTPS_PROXY=$HTTPSPROXY

ENV DEBIAN_FRONTEND noninteractive

RUN dpkg --add-architecture i386 && \
	apt-get -y update && \
	apt-get -y upgrade && \
	apt-get install --no-install-recommends -y \
	gnupg \
	ca-certificates \
	wget && \
	apt-key adv --keyserver keyserver.ubuntu.com ${HTTPPROXY:+--keyserver-options "http-proxy=$HTTPPROXY"} --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF && \
#								PROXY INJECT        ^^^^^^^^^^^ \
	apt-get -y update && \
	apt-get install --no-install-recommends -y \
	autoconf \
	automake \
	build-essential \
	ccache \
	chrpath \
	cpio \
	curl \
	debianutils \
	dfu-util \
	diffstat \
#	doxygen \
	file \
	gawk \
	gcc-multilib \
	git \
	git-core \
	iproute2 \
	iputils-ping \
	libglib2.0-dev \
	libstdc++6:i386 \
	libncurses5:i386 \
	libz1:i386 \
	libc6:i386 \
	libc6-dev-i386 \ 
	g++-multilib \
	libtool \
	locales \
	make \
	net-tools \
	pkg-config \
	python \
	python3 \
	python3-pip \
	python3-pexpect \
	socat \
	sudo \
	texinfo \
	unzip \
	xz-utils && \
	rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

ENV PKG_CONFIG_PATH=/usr/lib/i386-linux-gnu/pkgconfig
ENV DISPLAY=:0

#make user w/ sudo rights
RUN useradd -mG plugdev user \
	&& echo 'user ALL = NOPASSWD: ALL' > /etc/sudoers.d/user \
	&& chmod 0440 /etc/sudoers.d/user
#ARM gcc @  https://developer.arm.com/-/media/Files/downloads/gnu-a/8.3-2019.03/binrel/gcc-arm-8.3-2019.03-x86_64-arm-linux-gnueabihf.tar.xz
RUN wget -q https://developer.arm.com/-/media/Files/downloads/gnu-a/8.3-2019.03/binrel/${ARM_GCC}.tar.bz2 && tar xf ${ARM_GCC}.tar.bz2 && \
        rm -f ${ARM_GCC}.tar.bz2 && mkdir -p /opt/toolchains && mv ${ARM_GCC} /opt/toolchains/${ARM_GCC}

#BSP does NOT belong in the SDK docker... put in the bcbprj!
#TI AM335x BSP binary http://software-dl.ti.com/processor-sdk-linux/esd/AM335X/latest/exports/am335x-evm-linux-sdk-bin-06.00.00.07.tar.xz
#RUN wget -q http://software-dl.ti.com/processor-sdk-linux/esd/AM335X/latest/exports/am335x-evm-linux-sdk-bin-06.00.00.07.tar.xz && \
#	mkdir -p /opt/sdks && \
#	tar xf am335x-evm-linux-sdk-bin-06.00.00.07.tar.xz --directory /opt/sdks && \
#	rm -f /opt/sdks/ti-processor-sdk-linux-am335x-evm-bin-06.00.00.07/filesystem/arago-tiny* && \
#	rm -f /opt/sdks/ti-processor-sdk-linux-am335x-evm-bin-06.00.00.07/filesystem/tisdk* && \
#	rm -f /opt/sdks/ti-processor-sdk-linux-am335x-evm-bin-06.00.00.07/filesystem/*.ubi && \
#	rm -f am335x-evm-linux-sdk-bin-06.00.00.07.tar.xz

ADD ./src /home/user
RUN chown -R user: /home/user

ENV PATH=/opt/toolchains/$ARM_GCC/bin:$PATH \       
	TOOLCHAIN_SYS=arm-linux-gnueabihf \
	TOOLCHAIN_PREFIX=$TOOLCHAIN_SYS- \
	CC=${TOOLCHAIN_PREFIX}gcc \
	CXX=${TOOLCHAIN_PREFIX}g++ \
	GDB=${TOOLCHAIN_PREFIX}gdb \
	CPP="${TOOLCHAIN_PREFIX}gcc -E" \
	NM=${TOOLCHAIN_PREFIX}nm \
	AS=${TOOLCHAIN_PREFIX}as \
	AR=${TOOLCHAIN_PREFIX}ar \
	RANLIB=${TOOLCHAIN_PREFIX}ranlib \
	OBJCOPY=${TOOLCHAIN_PREFIX}objcopy \
	OBJDUMP=${TOOLCHAIN_PREFIX}objdump \
	STRIP=${TOOLCHAIN_PREFIX}strip \
	CONFIGURE_FLAGS="--target=arm-oe-linux-gnueabi --host=arm-oe-linux-gnueabi --build=i686-linux" \
	CPPFLAGS=" -march=armv7-a -marm -mthumb-interwork -mfloat-abi=hard -mfpu=neon -mtune=cortex-a8" \
	CFLAGS="$CPPFLAGS" \
	CXXFLAGS="$CPPFLAGS" \
	LDFLAGS="-Wl,-rpath=/home/cvondrac/bc2019/badgeR-git/bootfs/lib" \
	PS1="\[\e[32;1m\][bcbuildr]\[\e[0m\]:\w> " \
	CROSS_COMPILE=$TOOLCHAIN_PREFIX

CMD ["/workdir/bcbuild.sh"]
USER user
WORKDIR /workdir
VOLUME ["/workdir"]

