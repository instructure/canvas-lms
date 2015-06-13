FROM selenium/node-firefox-debug:2.45.0

# Downgrade selenium server
RUN wget --no-verbose http://selenium-release.storage.googleapis.com/2.43/selenium-server-standalone-2.43.1.jar -O /opt/selenium/selenium-server-standalone.jar

# Downgrade firefox
RUN mkdir -p /opt/firefox \
 && wget --no-verbose http://ftp.mozilla.org/pub/mozilla.org/firefox/releases/34.0/linux-x86_64/en-US/firefox-34.0.tar.bz2 -O /tmp/firefox.tar.bz2 \
 && bunzip2 /tmp/firefox.tar.bz2 \
 && cd /opt \
 && tar xvf /tmp/firefox.tar \
 && rm /tmp/firefox.tar \
 && rm /usr/bin/firefox \
 && ln -s /opt/firefox/firefox /usr/bin/firefox

COPY entry_point.sh /opt/bin/entry_point.sh
RUN chmod +x /opt/bin/entry_point.sh

EXPOSE 4444
EXPOSE 5900
