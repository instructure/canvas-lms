FROM buildpack-deps:jessie

RUN apt-get update && apt-get install -y unzip

# Install consul
RUN curl -O -L -J https://dl.bintray.com/mitchellh/consul/0.5.2_linux_amd64.zip
RUN unzip -d /usr/local/bin/ 0.5.2_linux_amd64.zip

ENV DOCKER_HOST unix:///var/run/docker.sock

COPY entry_point.sh /opt/bin/entry_point.sh

ENTRYPOINT ["/opt/bin/entry_point.sh"]
