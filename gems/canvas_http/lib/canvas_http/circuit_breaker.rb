# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

require "redis"

module CanvasHttp
  # For managing host specific failure history
  # so that in cases where there is a downstream service
  # that is failing, we can stop wasting server time
  # blocking on responses that aren't coming.
  #
  # Threshold, interval, and window callbacks are all provided
  # with a host so that it's possible for consuming
  # application to configure different parameters
  # for different services
  #
  # e.g.
  #
  # CanvasHttp::CircuitBreaker.threshold = lambda do |domain|
  #  Setting.get("http_cb_#{domain}_threshold", 20).to_i
  # end
  #
  module CircuitBreaker
    DEFAULT_THRESHOLD = 10
    DEFAULT_INTERVAL = 15
    DEFAULT_WINDOW = 20

    class << self
      attr_writer :threshold, :interval, :window
      attr_accessor :redis

      def tripped?(domain)
        return false if redis_client.nil?

        !redis_client.get(tripped_key(domain), failsafe: nil).nil?
      end

      def trip_if_necessary(domain)
        return if redis_client.nil?

        key = threshold_key(domain)
        current_count = redis_client.pipelined(key) do |pipeline|
          pipeline.setnx(key, 0)
          pipeline.expire(key, window(domain))
          pipeline.incr(key)
        end.last
        if current_count > threshold(domain)
          redis_client.setex(tripped_key(domain), interval(domain), "1")
          CanvasHttp.logger.warn("CANVAS_HTTP CB_TRIP ON #{domain} | interval: #{interval(domain)} | thresh: #{threshold(domain)} | window: #{window(domain)}")
        end
      rescue Redis::BaseConnectionError
        # ignore
      end

      def tripped_key(domain)
        "http_cb_tripped_#{domain}"
      end

      def threshold_key(domain)
        "http_cb_counter_#{domain}"
      end

      def redis_client
        @redis.respond_to?(:call) ? @redis.call : @redis || nil
      end

      def threshold(domain)
        (@threshold.respond_to?(:call) ? @threshold.call(domain) : @threshold) || DEFAULT_THRESHOLD
      end

      def interval(domain)
        (@interval.respond_to?(:call) ? @interval.call(domain) : @interval) || DEFAULT_INTERVAL
      end

      def window(domain)
        (@window.respond_to?(:call) ? @window.call(domain) : @window) || DEFAULT_WINDOW
      end
    end
  end
end
