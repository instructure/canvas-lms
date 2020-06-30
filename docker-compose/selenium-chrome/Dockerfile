ARG SELENIUM_VERSION=3.141.59-20200525
FROM selenium/standalone-chrome-debug:$SELENIUM_VERSION

COPY entry_point.sh /opt/bin/custom_entry_point.sh
USER root
RUN chmod +x /opt/bin/custom_entry_point.sh
USER seluser

EXPOSE 4444

CMD ["/opt/bin/custom_entry_point.sh"]
