FROM starlord.inscloudgate.net/jenkins/core:focal
RUN \
  --mount=type=bind,from=local/cache-helper,source=/tmp/dst,target=/cache-helper \
  --mount=target=/host \
  mkdir -p /tmp/dst && \
  tar --no-same-owner -xf /cache-helper/js.tar -C /tmp/dst && \
  cp /host/schema.graphql /tmp/dst/schema.graphql
