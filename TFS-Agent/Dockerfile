FROM registry.centos.org/centos:7
ENV CENTOS_VERSION=7

USER root

RUN yum -y install \
       yum-plugin-ovl \
       deltarpm \
       epel-release \
       unzip \
       libunwind \
       gettext\
       libcurl-devel \
       openssl-devel \
       zlib \
       libicu-devel \
	   centos-release-dotnet.noarch \
	   rh-dotnet21-2.1-2.el7.x86_64 \
	   install ca-certificates \
 && yum -y install \
       jq \
 && yum clean all \
 && update-ca-trust force-enable

ADD root_ca.pem /etc/pki/ca-trust/source/anchors/root_ca.pem

RUN mkdir ~/.ssh/ \
 && echo -e "Host visualstudio.com\n	StrictHostKeyChecking no" > ~/.ssh/config

RUN localedef -i en_GB -f UTF-8 en_GB.UTF-8
RUN localedef -i en_US -f UTF-8 en_US.UTF-8 && echo 'LANG="en_GB.UTF-8"' > /etc/locale.conf && update-ca-trust extract

WORKDIR /vsts

COPY ./start.sh .
COPY ./vsts-agent-linux-x64-2.136.1.tar.gz .
RUN chmod +x start.sh && chgrp -R 0 /vsts &&  chmod -R g=u /vsts

ENV LANG en_GB.UTF-8
ENV LANGUAGE en_GB:en
ENV LC_ALL en_GB.UTF-8

USER 1001

CMD ["./start.sh"]
