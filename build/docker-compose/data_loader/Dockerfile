FROM alpine:3.4

RUN apk --update add \
      bash \
      curl \
      less \
      groff \
      jq \
      python \
      tar \
      py-pip && \
      pip install --upgrade awscli s3cmd

COPY ./fetch-volumes /
COPY ./push-volumes /
COPY ./wait-for-it /

CMD bash -c "/fetch-volumes $BASE_DOCKER_VOLUME_ARCHIVE && while true; do sleep 86400; done"
