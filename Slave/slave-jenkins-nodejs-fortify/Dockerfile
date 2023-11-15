FROM openregistry.hml.pine.com/cicd/jenkins-slave-nodejs-10:latest

MAINTAINER Leandro Alves Morilha

USER root
ADD root_ca.pem /etc/pki/ca-trust/source/anchors/root_ca.pem

COPY . ./
RUN yum install rpm-build -y && ./Fortify_SCA_and_Apps_19.1.0_linux_x64.run --mode unattended && chmod -R 777 /opt/Fortify/ && chmod -R 777 /home/jenkins/ && \
    update-ca-trust enable && update-ca-trust extract && \
	/opt/Fortify/Fortify_SCA_and_Apps_19.1.0/jre/bin/keytool -import -alias capine -keystore /opt/Fortify/Fortify_SCA_and_Apps_19.1.0/jre/lib/security/cacerts -file /etc/pki/ca-trust/source/anchors/root_ca.pem -storepass changeit -noprompt

USER 1001