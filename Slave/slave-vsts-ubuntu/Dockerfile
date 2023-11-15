FROM microsoft/vsts-agent:ubuntu-16.04-docker-18.06.1-ce

USER root

ADD . ./

RUN mkdir agent && cd agent && tar -xz --no-same-owner -f ../agent.tgz && cd .. && rm agent.tgz && mkdir /usr/share/ca-certificates/extra && \
 mv root_ca.pem /usr/share/ca-certificates/extra/ && update-ca-certificates && chown -R 1001:0 /vsts && chmod +x /vsts/start.sh

USER 1001

CMD ["./start.sh"]