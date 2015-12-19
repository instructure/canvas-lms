FROM emmenko/nodejs-karma:0.2.0

RUN mkdir /app
WORKDIR /app

COPY entry_point.sh /opt/bin/entry_point.sh

ENTRYPOINT ["/opt/bin/entry_point.sh"]
