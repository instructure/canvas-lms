# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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
  class RedisConfig
    attr_reader :redis

    def initialize(servers, database=nil, options=nil)
      @redis = RedisConfig.from_servers(servers, options)
      @redis.select database if database.present?
    end

    def self.from_settings(settings)
      RedisConfig.new(
        settings[:servers],
        settings[:database],
        settings.except(:servers, :database).symbolize_keys
      )
    end

    def self.factory
      Bundler.require 'redis'
      ::Redis::Store::Factory
    end

    def self.url_to_redis_options(s)
      factory.extract_host_options_from_uri(s)
    end

    def self.from_servers(servers, options)
      raw_conn = factory.create(servers.map { |s|
        # convert string addresses to options hash, and disable redis-cache's
        # built-in marshalling code
        url_to_redis_options(s).merge(options || {})
      })
      ::Canvas::RedisWrapper.new(raw_conn)
    end
  end
end
