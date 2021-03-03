# frozen_string_literal: true

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
require 'inst_statsd'

module EventStream
  ##
  # EventStream::Logger is a simple wrapper
  # for a standard Rails.logger which structures
  # log messages from EventStream operations to have some
  # common structure and knows a few common message types
  # to turn directly into statsd packages with a common
  # namespace.
  #
  # If you want to use it in your event stream, you can add
  # an invocation to your stream callbacks:
  #
  # EventStream::Stream.new do
  #   stream.on_insert do |record|
  #     EventStream::Logger.info('STREAM', identifier, 'insert', record.to_json)
  #   end
  #
  #   stream.on_error do |operation, record, exception|
  #     EventStream::Logger.error('STREAM', identifier, operation, record.to_json, exception.message.to_s)
  #   end
  # end
  #
  # TODO: Maybe make this happen automatically for any stream?^
  module Logger
    def self.logger
      Rails.logger
    end

    def self.info(type, identifier, operation, record)
      logger.info "[#{type}:INFO] #{identifier}:#{operation} #{record}"
    end

    def self.error(type, identifier, operation, record, message)
      logger.error "[#{type}:ERROR] #{identifier}:#{operation} #{record} [#{message}]"
      InstStatsd::Statsd.increment("event_stream_failure.stream.#{InstStatsd::Statsd.escape(identifier)}")
      if message.blank?
        InstStatsd::Statsd.increment("event_stream_failure.exception.blank")
      elsif message.include?("No live servers")
        InstStatsd::Statsd.increment("event_stream_failure.exception.no_live_servers")
      elsif message.include?("Unavailable")
        InstStatsd::Statsd.increment("event_stream_failure.exception.unavailable")
      else
        InstStatsd::Statsd.increment("event_stream_failure.exception.other")
      end
    end
  end
end
