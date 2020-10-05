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
require 'spec_helper'
require_dependency "canvas/cache/local_redis_cache"

module Canvas
  module Cache
    class SlowTestRedisCache < LocalRedisCache
      def write(k, v, opts)
        super
        sleep(0.1) # slow it down so we can test atomicity
      end
    end

    RSpec.describe LocalRedisCache do
      let(:redis_conf_hash) do
        rc = Canvas.redis_config
        {
          store: "redis",
          redis_url: rc.fetch("servers", ["redis://redis"]).first,
          redis_db: rc.fetch("database", 1)
        }
      end

      before(:each) do
        skip("Must have a local redis available to run this spec") unless Canvas.redis_enabled?
        @slow_cache = SlowTestRedisCache.new(redis_conf_hash)
        @fast_cache = LocalRedisCache.new(redis_conf_hash)
      end

      after(:each) do
        @fast_cache.clear
      end

      it "writes sets of keys atomically" do
        data_set = {
          "keya" => "vala",
          "keyb" => "valb",
          "keyc" => "valc",
          "keyd" => "vald",
          "keye" => "vale",
          "keyf" => "valf",
          "keyg" => "valg",
          "keyh" => "valh",
        }
        read_set = {}
        slow_thread = Thread.new do
          @slow_cache.write_set(data_set)
        end
        fast_thread = Thread.new do
          while @fast_cache.read('keya') != 'vala'
            sleep(0.025)
          end
          # once any data is there, it should all be there
          data_set.each do |k,v|
            val = @fast_cache.read(k)
            read_set[k] = val unless val.nil?
          end
        end
        fast_thread.join
        slow_thread.join
        expect(read_set == data_set).to be_truthy
      end
    end
  end
end
