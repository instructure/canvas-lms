# frozen_string_literal: true

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
        @fast_cache.clear(force: true)
      end

      def new_redis_client
        LocalRedisCache.new(redis_conf_hash)
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

      it "handles concurrent traffic" do
        skip 'FOO-1895 4/21/21'
        lock_taken = false
        cache_key = "some-cache-key"
        cache_value = "THE VALUE"
        v1 = v2 = v3 = nil
        # using threads, but really testing against
        # many processes talking to the same redis
        t1 = Thread.new do
          c1 = new_redis_client
          v1 = c1.fetch(cache_key, expires_in: 30.seconds, race_condition_ttl: 10.seconds) do
            lock_taken = true
            sleep(0.2) # allow other threads to run and try for lock
            cache_value.dup
          end
        end
        t2 = Thread.new do
          c2 = new_redis_client
          sleep(0.1) until lock_taken # make sure t1 goes first
          v2 = c2.fetch(cache_key, expires_in: 30.seconds, race_condition_ttl: 10.seconds) do
            raise RuntimeError, "should have waited for t1"
          end
        end
        t3 = Thread.new do
          c3 = new_redis_client
          sleep(0.1) until lock_taken # make sure t1 goes first
          v3 = c3.fetch(cache_key, expires_in: 30.seconds, race_condition_ttl: 10.seconds) do
            raise RuntimeError, "should have waited for t1"
          end
        end
        t1.join
        t2.join
        t3.join
        expect(v1).to eq(cache_value)
        expect(v2).to eq(cache_value)
        expect(v3).to eq(cache_value)
      end

      it "will only clear once in a short window, unless forced" do
        skip 'FOO-1895 4/21/21'
        @fast_cache.write("pre-clear-key", "pre-clear-value")
        expect(@fast_cache.read("pre-clear-key")).to eq("pre-clear-value")
        @fast_cache.clear
        expect(@fast_cache.read("pre-clear-key")).to be_nil
        @fast_cache.write("post-clear-key", 'post-key-val')
        @fast_cache.clear
        expect(@fast_cache.read("pre-clear-key")).to be_nil
        expect(@fast_cache.read("post-clear-key")).to eq('post-key-val')
        @fast_cache.clear(force: true)
        expect(@fast_cache.read("pre-clear-key")).to be_nil
        expect(@fast_cache.read("post-clear-key")).to be_nil
      end
    end
  end
end
