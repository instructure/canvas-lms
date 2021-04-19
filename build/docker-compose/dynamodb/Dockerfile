FROM amazon/dynamodb-local:1.12.0
USER root
RUN mkdir -p /data
CMD ["-jar", "DynamoDBLocal.jar", "-dbPath", "/data"]
