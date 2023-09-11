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
#

require "aws-sdk-kinesis"
require "json"
require "active_support"
require "active_support/core_ext/object/blank"

module LiveEvents
  class Client
    ATTRIBUTE_BLACKLIST = [:compact_live_events].freeze

    attr_reader :stream_name, :stream_client

    def self.config
      res = LiveEvents.settings
      if res["stub_kinesis"]
        return res.dup unless Rails.env.production?

        LiveEvents.logger&.warn(
          "LIVE_EVENTS: stub_kinesis was set in production with value #{res["stub_kinesis"]}"
        )
      end
      return nil unless res && res["kinesis_stream_name"].present? &&
                        (res["aws_region"].present? || res["aws_endpoint"].present?)

      unless (defined?(Rails) && Rails.env.production?) ||
             res["custom_aws_credentials"] ||
             (res["aws_access_key_id"].present? && res["aws_secret_access_key_dec"].present?)
        # Creating Kinesis client with no creds will hang if can't connect to AWS to get creds
        LiveEvents.logger&.warn(
          "LIVE EVENTS: no creds given for kinesis in non-prod environment. Disabling."
        )
        return nil
      end

      res.dup
    end

    def initialize(config = nil, aws_stream_client = nil, aws_stream_name = nil, worker: nil)
      config ||= LiveEvents::Client.config
      @stream_client = aws_stream_client || Aws::Kinesis::Client.new(Client.aws_config(config))
      @stream_name = aws_stream_name || config["kinesis_stream_name"]
      if worker
        @worker = worker
        @worker.stream_client = @stream_client
        @worker.stream_name = @stream_name
      end
    end

    def self.aws_config(plugin_config)
      aws = {}

      if plugin_config["aws_access_key_id"].present? && plugin_config["aws_secret_access_key_dec"].present?
        aws[:access_key_id] = plugin_config["aws_access_key_id"]
        aws[:secret_access_key] = plugin_config["aws_secret_access_key_dec"]
      end

      if plugin_config["custom_aws_credentials"]
        aws[:credentials] = LiveEvents.aws_credentials(plugin_config)
      end

      aws[:region] = plugin_config["aws_region"].presence || "us-east-1"

      if plugin_config["aws_endpoint"].present?
        # to expose the strange error where this endpoint is present but not a real endpoint
        # and to avoid breaking live events if that error occurs
        endpoint = URI.parse(plugin_config["aws_endpoint"])
        if URI::HTTPS === endpoint || URI::HTTP === endpoint
          aws[:endpoint] = plugin_config["aws_endpoint"]
        else
          LiveEvents.logger.warn("invalid endpoint value #{plugin_config["aws_endpoint"]}")
        end
      end

      aws
    end

    def valid?
      @stream_client.describe_stream(stream_name: @stream_name, limit: 1)
      true
    rescue Aws::Kinesis::Errors::ServiceError
      false
    end

    def post_event(event_name, payload, time = Time.now, ctx = {}, partition_key = nil)
      statsd_prefix = "live_events.events"
      tags = { event: event_name }

      ctx ||= {}
      attributes = ctx.except(*ATTRIBUTE_BLACKLIST).merge({
                                                            event_name:,
                                                            event_time: time.utc.iso8601(3)
                                                          })

      event = {
        attributes:,
        body: payload
      }

      # We don't care too much about the partition key, but it seems safe to
      # let it be the user_id when that's available.
      partition_key ||= ctx["user_id"]&.try(:to_s) || rand(1000).to_s

      pusher = @worker || LiveEvents.worker

      unless pusher.push(event, partition_key)
        LiveEvents.logger.error("Error queueing job for live event: #{event.to_json}")
        LiveEvents.statsd&.increment("#{statsd_prefix}.queue_full_errors", tags:)
      end
    end
  end
end
