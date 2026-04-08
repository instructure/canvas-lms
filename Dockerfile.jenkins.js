FROM 948781806214.dkr.ecr.us-east-1.amazonaws.com/docker.io/instructure/core:jammy
RUN \
  --mount=type=bind,from=local/cache-helper,source=/tmp/dst,target=/cache-helper \
  --mount=target=/host \
  mkdir -p /tmp/dst && \
  tar --no-same-owner -xf /cache-helper/js.tar -C /tmp/dst && \
  cp /host/schema.graphql /tmp/dst/schema.graphql
