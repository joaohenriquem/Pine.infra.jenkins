FROM registry.redhat.io/dotnet/dotnet-31-jenkins-slave-rhel7:latest

MAINTAINER Leandro Alves Morilha

USER root

ADD root_ca.pem /etc/pki/ca-trust/source/anchors/root_ca.pem
RUN update-ca-trust enable && \
	update-ca-trust extract

USER 1001