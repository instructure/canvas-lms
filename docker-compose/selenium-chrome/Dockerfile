# Keep this image version tag synced with Gemfile.d/test.rb
FROM selenium/standalone-chrome-debug:2.53.0

COPY entry_point.sh /opt/bin/custom_entry_point.sh
RUN chmod +x /opt/bin/custom_entry_point.sh

EXPOSE 4444

CMD ["/opt/bin/custom_entry_point.sh"]
