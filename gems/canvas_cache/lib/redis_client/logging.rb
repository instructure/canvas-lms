# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

class RedisClient
  module Logging
    COMPACT_LINE = "Redis (%{request_time_ms}ms) %{command} %{key} [%{host}]"
    NON_KEY_COMMANDS = %w[eval evalsha].freeze
    SET_COMMANDS = %w[set setex].freeze

    def call(request, config)
      client.last_command_at = start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      response = super
    ensure
      log_style = CanvasCache::Redis.log_style
      if log_style != "off" && Rails.logger
        command = request.first

        end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        message = {
          message: "redis_request",
          command:,
          # request_size is the sum of all the string parameters send with the command.
          request_size: request.sum { |c| c.to_s.size } - command.to_s.size,
          request_time_ms: ((end_time - start_time) * 1000).round(3),
          host: config.server_url,
        }

        unless NON_KEY_COMMANDS.include?(command)
          message[:key] = case command
                          when "mset"
                            request[1..].select.with_index { |_, i| i.even? }
                          when "mget", "scan"
                            request[1..]
                          else
                            request[1]
                          end
        end

        if defined?(Marginalia)
          message[:controller] = Marginalia::Comment.controller
          message[:action] = Marginalia::Comment.action
          message[:job_tag] = Marginalia::Comment.job_tag
        end

        if SET_COMMANDS.include?(command) && Thread.current[:last_cache_generate]
          # :last_cache_generate comes from the instrumentation added in
          # config/initializers/cache_store.rb in canvas.
          #
          # TODO: port the code in that initializer to something in thi gem.
          #
          # This is necessary because the Rails caching layer doesn't pass this
          # information down to the Redis client -- we could try to infer it by
          # looking for reads followed by writes to the same key, but this would be
          # error prone, especially since further cache reads can happen inside the
          # generation block.
          message[:generate_time_ms] = Thread.current[:last_cache_generate] * 1000
          Thread.current[:last_cache_generate] = nil
        end
        e = $!
        if e
          message[:error] = e.to_s
          message[:response_size] = 0
        else
          message[:response_size] = response&.size || 0
        end

        logline = format_log_message(message, log_style)
        Rails.logger.debug(logline)
      end
    end

    def format_log_message(message, log_style)
      if log_style == "json"
        JSON.generate(message.compact)
      else
        message[:key] ||= "-"
        COMPACT_LINE % message
      end
    end
  end
end
