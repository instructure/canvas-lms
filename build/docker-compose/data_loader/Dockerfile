FROM alpine:3.8

RUN apk add --no-cache \
  bash curl less groff jq tar \
  python2 py2-pip python2-dev \
  build-base ca-certificates \
  openssl=1.0.2u-r0 \
  libcrypto1.0=1.0.2u-r0 \
  libssl1.0=1.0.2u-r0

RUN pip2 install --no-cache-dir --upgrade 'pip<21' 'setuptools<45' 'wheel<0.35'
RUN pip2 install --no-cache-dir \
  'PyYAML==5.3.1' \
  'awscli==1.19.112' \
  's3cmd==2.4.0'

COPY ./fetch-volumes /
COPY ./push-volumes /
COPY ./wait-for-it /

CMD bash -c "/fetch-volumes $BASE_DOCKER_VOLUME_ARCHIVE && while true; do sleep 86400; done"
