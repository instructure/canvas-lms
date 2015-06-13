#
# Copyright (C) 2014 Instructure, Inc.
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
#

module Auditors
  def self.stream(&block)
    ::EventStream::Stream.new(&block).tap do |stream|
      stream.raise_on_error = Rails.env.test?

      stream.on_insert do |record|
        Auditors.logger.info "[AUDITOR:INFO] #{identifier}:insert #{record.to_json}"
      end

      stream.on_error do |operation, record, exception|
        message = exception.message.to_s
        Auditors.logger.error "[AUDITOR:ERROR] #{identifier}:#{operation} #{record.to_json} [#{message}]"
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

  def self.logger
    Rails.logger
  end
end
