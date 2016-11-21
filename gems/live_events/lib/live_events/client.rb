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

require 'aws-sdk'
require 'json'
require 'active_support'
require 'active_support/core_ext/object/blank'

module LiveEvents

  class Client
    def self.config
      res = LiveEvents.plugin_settings.try(:settings)
      return nil unless res && !res['kinesis_stream_name'].blank? &&
                               !res['aws_access_key_id'].blank? &&
                               !res['aws_secret_access_key_dec'].blank? &&
                               (!res['aws_region'].blank? || !res['aws_endpoint'].blank?)

      res.dup
    end

    def initialize(config = nil)
      config ||= LiveEvents::Client.config
      @kinesis = Aws::Kinesis::Client.new(Client.aws_config(config))
      @stream_name = config['kinesis_stream_name']
    end

    def self.aws_config(plugin_config)
      aws = {
        :access_key_id => plugin_config['aws_access_key_id'],
        :secret_access_key => plugin_config['aws_secret_access_key_dec'],
      }

      aws[:region] = plugin_config['aws_region'].presence || 'us-east-1'

      if !plugin_config['aws_endpoint'].blank?
        aws[:endpoint] = plugin_config['aws_endpoint']
      end

      aws
    end

    def post_event(event_name, payload, time = Time.now, ctx = {}, partition_key = nil)
      statsd_prefix = "live_events.events.#{event_name}"

      ctx ||= {}
      attributes = ctx.merge({
        event_name: event_name,
        event_time: time.utc.iso8601
      })

      event = {
        attributes: attributes,
        body: payload
      }

      # We don't care too much about the partition key, but it seems safe to
      # let it be the user_id when that's available.
      partition_key ||= (ctx["user_id"] && ctx["user_id"].try(:to_s)) || rand(1000).to_s

      event_json = JSON.dump(event)

      job = Proc.new {
        begin
          @kinesis.put_record(stream_name: @stream_name,
                              data: event_json,
                              partition_key: partition_key)

          LiveEvents.statsd.increment("#{statsd_prefix}.sends") if LiveEvents.statsd
        rescue => e
          LiveEvents.logger.error("Error posting event #{e} event: #{event_json}")
          LiveEvents.statsd.increment("#{statsd_prefix}.send_errors") if LiveEvents.statsd
        end
      }

      unless LiveEvents.worker.push(job)
        LiveEvents.logger.error("Error queueing job for worker event: #{event_json}")
        LiveEvents.statsd.increment("#{statsd_prefix}.queue_full_errors") if LiveEvents.statsd
      end
    end
  end
end
