FROM openshift/jenkins-slave-base-centos7

MAINTAINER Leandro Alves Morilha

USER root

RUN yum -y install skopeo
RUN yum install ca-certificates

RUN update-ca-trust force-enable
ADD root_ca.pem /etc/pki/ca-trust/source/anchors/root_ca.pem
RUN update-ca-trust extract

USER 1001