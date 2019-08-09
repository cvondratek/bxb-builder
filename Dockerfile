FROM ubuntu:18.04

ARG TI_SDK=
ARG SOME_ARG=argval

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
	wget -q -O - https://pkg.jenkins.io/debian/jenkins-ci.org.key | apt-key add - && \
	echo "deb http://pkg.jenkins.io/debian-stable binary/" | tee /etc/apt/sources.list.d/jenkins.list && \
	apt-get -y update && \
	apt-get install --no-install-recommends -y \
	autoconf \
	automake \
	build-essential \
	ccache \
	curl \
	dfu-util \
	doxygen \
	file \
	g++ \
	gcc \
	gcc-multilib \
	git \
	git-core \
	iproute2 \
	jenkins \
	libglib2.0-dev \
	libtool \
	locales \
	make \
	net-tools \
	openbox \
	openjdk-8-jdk \
	pkg-config \
	python3-pip \
	python3-ply \
	python3-setuptools \
	python-xdg \
	qemu \
	socat \
	sudo \
	texinfo \
	xz-utils && \
#	wget -O dtc.deb http://security.ubuntu.com/ubuntu/pool/main/d/device-tree-compiler/device-tree-compiler_1.4.7-1_amd64.deb && \
#	dpkg -i dtc.deb && \
#	wget -O renode.deb https://github.com/renode/renode/releases/download/v1.6.2/renode_1.6.2_amd64.deb && \
#	apt install -y ./renode.deb && \
#	rm dtc.deb renode.deb && \
	rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

#make jenkins the primary user w/ sudo rights
RUN usermod -aG plugdev jenkins \
	&& echo 'jenkins ALL = NOPASSWD: ALL' > /etc/sudoers.d/jenkins \
	&& chmod 0440 /etc/sudoers.d/jenkins

#am335x
ADD ./downloads/$TI_SDK /tmp
RUN sudo /bin/bash /tmp/$TI_SDK && \ 
	rm -rf /tmp/$TI_SDK

ENV PKG_CONFIG_PATH=/usr/lib/i386-linux-gnu/pkgconfig
ENV DISPLAY=:0

ADD ./entrypoint.sh /entrypoint.sh
#ADD ./src/jenkins_home/config.xml /var/lib/jenkins/config.xml
#ADD ./src/jenkins_home/proxy.xml /var/lib/jenkins/proxy.xml

#write a proxy.xml...
RUN	if [[ -n $http_proxy ]]; then \
		rm -rf /var/lib/jenkins/proxy.xml  && \
		PROXYPORT=$(echo $HTTPPROXY | awk -F ':' '{print $3}' | grep -o '[0-9]\+') && \
		PROXYHOST=$(echo $HTTPPROXY | awk -F '\/\/' '{print $2}' | awk -F ':' '{print $1}') && \
		echo Extracted proxy host: $PROXYHOST && \
		echo Extracted proxy port: $PROXYPORT && \
		printf "<?xml version='1.1' encoding='UTF-8'?>\n<proxy>\n\t<name>%s</name>\n\t<port>%s</port>\n</proxy>\n" $PROXYHOST $PROXYPORT >> /var/lib/jenkins/proxy.xml; \
	fi

#add plugins from local cache, to speedify test cycles
ADD ./jenkins_plugins/* /tmp/

RUN chown -R jenkins: /var/lib/jenkins

#EXPOSE 5900

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]
USER jenkins
WORKDIR /workdir
VOLUME ["/workdir"]

#ARG VNCPASSWD=zephyr
#RUN mkdir ~/.vnc && x11vnc -storepasswd ${VNCPASSWD} ~/.vnc/passwd


