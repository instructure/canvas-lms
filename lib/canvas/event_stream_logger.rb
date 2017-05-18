#
# Copyright (C) 2015 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

module Canvas
  module EventStreamLogger
    def self.logger
      Rails.logger
    end

    def self.info(type, identifier, operation, record)
      logger.info "[#{type}:INFO] #{identifier}:#{operation} #{record}"
    end

    def self.error(type, identifier, operation, record, message)
      logger.error "[#{type}:ERROR] #{identifier}:#{operation} #{record} [#{message}]"
      CanvasStatsd::Statsd.increment("event_stream_failure.stream.#{CanvasStatsd::Statsd.escape(identifier)}")
      if message.blank?
        CanvasStatsd::Statsd.increment("event_stream_failure.exception.blank")
      elsif message.include?("No live servers")
        CanvasStatsd::Statsd.increment("event_stream_failure.exception.no_live_servers")
      elsif message.include?("Unavailable")
        CanvasStatsd::Statsd.increment("event_stream_failure.exception.unavailable")
      else
        CanvasStatsd::Statsd.increment("event_stream_failure.exception.other")
      end
    end
  end
end
