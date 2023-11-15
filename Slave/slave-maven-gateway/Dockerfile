FROM registry.centos.org/openshift/jenkins-slave-maven-centos7

USER 0

ENV JAVA_HOME="/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.181-3.b13.el7_5.x86_64"
RUN mkdir -p /opt/migration && \
    chmod 777 /opt/migration
ADD . /opt/migration
RUN $JAVA_HOME/bin/keytool -importcert -alias /opt/migration/gatewayhml -file /opt/migration/certificate-hml -keystore $JAVA_HOME/jre/lib/security/cacerts -storepass changeit -noprompt

USER 1001