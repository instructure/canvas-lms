# Keep this image version tag synced with Gemfile.d/test.rb
FROM selenium/standalone-firefox-debug:3.12.0-americium

COPY entry_point.sh /opt/bin/custom_entry_point.sh
USER root
RUN chmod +x /opt/bin/custom_entry_point.sh
USER seluser

EXPOSE 4444

CMD ["/opt/bin/custom_entry_point.sh"]
