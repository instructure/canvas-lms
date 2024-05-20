# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

require "redis/cluster"
require "spec_helper"
require "timecop"

describe CanvasCache::Redis do
  include_context "caching_helpers"

  describe ".enabled?" do
    before do
      CanvasCache::Redis.reset_config!
    end

    after do
      CanvasCache::Redis.reset_config!
    end

    it "is true when it finds a config" do
      allow(ConfigFile).to receive(:load).with("redis").and_return({ some: :data })
      expect(CanvasCache::Redis).to be_enabled
    end

    it "is false when config-less" do
      allow(ConfigFile).to receive(:load).with("redis").and_return(nil)
      expect(CanvasCache::Redis).to_not be_enabled
    end
  end

  describe "with redis" do
    before do
      skip("redis required to test") unless CanvasCache::Redis.enabled?
    end

    let(:redis_client) { CanvasCache::Redis.redis }

    it "doesn't marshall" do
      redis_client.set("test", 1)
      expect(redis_client.get("test")).to eq "1"
    end

    describe ".disconnect!" do
      it "generates a new client" do
        r = CanvasCache::Redis.redis
        expect(r).to eq(redis_client)
        CanvasCache::Redis.disconnect!
        r2 = CanvasCache::Redis.redis
        expect(r2).to_not be_nil
        expect(r2).to_not eq(r)
      end
    end

    describe "locking" do
      it "succeeds if the lock isn't taken" do
        expect(CanvasCache::Redis.lock("test1")).to be true
        expect(CanvasCache::Redis.lock("test2")).to be true
      end

      it "fails if the lock is taken" do
        expect(CanvasCache::Redis.lock("test1")).to be true
        expect(CanvasCache::Redis.lock("test1")).to be false
        expect(CanvasCache::Redis.unlock("test1")).to be true
        expect(CanvasCache::Redis.lock("test1")).to be true
      end

      it "lives forever if no expire time is given" do
        expect(CanvasCache::Redis.lock("test1")).to be true
        expect(CanvasCache::Redis.redis.ttl(CanvasCache::Redis.lock_key("test1"))).to eq(-1)
      end

      it "sets the expire time if given" do
        expect(CanvasCache::Redis.lock("test1", 15)).to be true
        ttl = CanvasCache::Redis.redis.ttl(CanvasCache::Redis.lock_key("test1"))
        expect(ttl).to be > 0
        expect(ttl).to be <= 15
      end
    end

    describe "exceptions" do
      it "protects against max # of client errors" do
        expect(redis_client._client.send(:raw_connection)).to receive(:call).and_raise(RedisClient::CommandError.new("ERR max number of clients reached")).once
        expect { redis_client.set("blah", "blah") }.to raise_error(Redis::ConnectionError)
        # a second call has tripped the circuit breaker
        expect { redis_client.set("blah", "blah") }.to raise_error(Redis::CannotConnectError)
      end

      it "passes through other command errors" do
        expect(redis_client._client.send(:raw_connection)).to receive(:call).and_raise(RedisClient::CommandError.new("NOSCRIPT No matching script. Please use EVAL.")).once
        expect { redis_client.evalsha("xxx") }.to raise_error(Redis::CommandError)

        expect(redis_client._client.send(:raw_connection)).to receive(:call).and_raise(RedisClient::CommandError.new("ERR no such key")).once
        expect { redis_client.get("no-such-key") }.to raise_error(Redis::CommandError)
      end

      describe "redis failure" do
        let(:cache) { ActiveSupport::Cache::RedisCacheStore.new(url: "redis://localhost:1234", circuit_breaker: { error_threshold: 1, error_timeout: 2 }) }

        before do
          allow(RedisClient::RubyConnection).to receive(:new).and_raise(RedisClient::TimeoutError)
        end

        it "does not fail cache.read" do
          override_cache(cache) do
            expect(Rails.cache.read("blah")).to be_nil
          end
        end

        it "does not call redis again after an error" do
          override_cache(cache) do
            expect(Rails.cache.read("blah")).to be_nil
            # call again, the .once means that if it hits Redis::Client again it'll fail
            expect(Rails.cache.read("blah")).to be_nil
          end
        end

        it "does not fail cache.write" do
          override_cache(cache) do
            expect(Rails.cache.write("blah", "someval")).to be false
          end
        end

        it "does not fail cache.delete" do
          override_cache(cache) do
            expect(Rails.cache.delete("blah")).to be false
          end
        end

        it "does not fail cache.delete for a ring" do
          override_cache(ActiveSupport::Cache::RedisCacheStore.new(url: ["redis://localhost:1234", "redis://localhost:4567"])) do
            expect(Rails.cache.delete("blah")).to be false
          end
        end

        it "does not fail cache.exist?" do
          override_cache(cache) do
            expect(Rails.cache.exist?("blah")).to be_falsey
          end
        end
      end
    end

    describe "json logging" do
      let(:key) { "mykey" }
      let(:key2) { "mykey2" }
      let(:val) { "myvalue" }

      before { allow(CanvasCache::Redis).to receive(:log_style).and_return("json") }

      it "logs information on the redis request" do
        log_lines = capture_log_messages do
          redis_client.set(key, val)
        end
        message = JSON.parse(log_lines.pop)
        expect(message["message"]).to eq("redis_request")
        expect(message["command"]).to eq("set")
        expect(message["key"]).to eq("mykey")
        expect(message["request_size"]).to eq((key + val).size)
        expect(message["response_size"]).to eq(2) # "OK"
        expect(message["host"]).not_to be_nil
        expect(message["request_time_ms"]).to be_a(Float)
      end

      it "does not log the lua eval code" do
        log_lines = capture_log_messages do
          redis_client.eval("local a = 1")
        end
        message = log_lines[0]
        expect(message["key"]).to be_nil
      end

      it "logs error on redis error response" do
        log_lines = capture_log_messages do
          expect { redis_client.eval("totes not lua") }.to raise_error(Redis::CommandError)
        end
        message = JSON.parse(log_lines.first)
        expect(message["response_size"]).to eq(0)
        expect(message["error"]).to be_a(String)
      end

      context "rails caching" do
        let(:cache) do
          ActiveSupport::Cache::RedisCacheStore.new(redis: redis_client)
        end

        it "logs the cache fetch block generation time" do
          Timecop.freeze do
            log_lines = capture_log_messages do
              # make sure this works with fetching nested fetches
              cache.fetch(key, force: true) do
                val = +"a1"
                val << cache.fetch(key2, force: true) do
                  Timecop.travel(Time.now.utc + 1.second)
                  # Cheat to cover the missing ActiveSupport::Notifications.subscription in config/inititalizers/cache_store.rb
                  # TODO: remove this hack when initializer is ported to gem and incorporated
                  Thread.current[:last_cache_generate] = 1
                  "b1"
                end
                Timecop.travel(Time.now.utc + 2.seconds)
                # Cheat to cover the missing ActiveSupport::Notifications.subscription in config/inititalizers/cache_store.rb
                # TODO: remove this hack when initializer is ported to gem and incorporated
                Thread.current[:last_cache_generate] = 3
                val << "a2"
              end
            end
            outer_message = JSON.parse(log_lines.pop)
            expect(outer_message["command"]).to eq("set")
            expect(outer_message["key"]).to end_with(key)
            expect(outer_message["request_time_ms"]).to be_a(Float)
            # 3000 (3s) == 2s outer fetch + 1s inner fetch
            expect(outer_message["generate_time_ms"]).to be_within(500).of(3000)

            inner_message = JSON.parse(log_lines.pop)
            expect(inner_message["command"]).to eq("set")
            expect(inner_message["key"]).to end_with(key2)
            expect(inner_message["request_time_ms"]).to be_a(Float)
            expect(inner_message["generate_time_ms"]).to be_within(500).of(1000)
          end
        end

        it "logs zero response size on cache miss" do
          cache.delete(key)
          log_lines = capture_log_messages do
            expect(cache.read(key)).to be_nil
          end
          message = JSON.parse(log_lines.pop)
          expect(message["command"]).to eq("get")
          expect(message["response_size"]).to eq(0)
        end
      end
    end

    it "logs compactly by default on the redis request" do
      # cache to avoid capturing a log line for db lookup
      CanvasCache::Redis.log_style
      log_lines = capture_log_messages do
        redis_client.set("mykey", "myvalue")
      end
      msg = log_lines.pop
      expect(msg).to match(/Redis \(\d+\.\d+ms\) set mykey \[.*\]/)
    end

    it "allows disabling redis logging" do
      allow(CanvasCache::Redis).to receive(:log_style).and_return("off")
      log_lines = capture_log_messages do
        redis_client.set("mykey", "myvalue")
      end
      expect(log_lines).to be_empty
    end

    describe "RedisClient::Twemproxy" do
      it "raises on unsupported commands" do
        expect { redis_client.keys }.to raise_error(CanvasCache::Redis::UnsupportedRedisMethod)
      end
    end

    context "with error protection" do
      before do
        CanvasCache::Redis.reset_config!
        CanvasCache::Redis.disconnect!
      end

      after do
        CanvasCache::Redis.reset_config!
        CanvasCache::Redis.disconnect!
      end

      it "uses the circuit breaker properly" do
        expect(ConfigFile).to receive(:load).with("redis").and_return(url: ["redis://redis-test-node-42:9999/"], reconnect_attempts: 0)
        expect(RedisClient::RubyConnection).to receive(:new).and_raise(RedisClient::TimeoutError, "intentional failure").twice

        now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        allow(Process).to receive(:clock_gettime).and_return(now)
        expect { redis_client.get("mykey") }.to raise_error(Redis::CannotConnectError)

        allow(Process).to receive(:clock_gettime).and_return(now + 4)
        expect { redis_client.get("mykey") }.to raise_error(Redis::CannotConnectError)
      end

      it "support failsafe with pipeline" do
        expect(redis_client.pipelined(failsafe: 2) { raise Redis::CannotConnectError }).to eq(2)
      end

      it "support failsafe with pipeline on a distributed client" do
        client = Redis::Distributed.new([redis_client.id])
        expect(client.pipelined("key", failsafe: 2) { raise Redis::CannotConnectError }).to eq(2)
      end
    end
  end

  describe "#disconnect_if_idle" do
    let(:redis) { CanvasCache::Redis.redis }
    let(:client) { redis._client }
    let(:raw_client) { client }

    shared_examples "disconnect_if_idle" do
      it "closes the connection if no command was ever received" do
        expect(raw_client).to receive(:close)
        client.disconnect_if_idle(Process.clock_gettime(Process::CLOCK_MONOTONIC))
      end

      it "does not close the connection if a commmand was recently received" do
        redis.get("key")
        expect(raw_client).not_to receive(:close)
        client.disconnect_if_idle(Process.clock_gettime(Process::CLOCK_MONOTONIC) - 10)
      end

      it "closes the connection if a commmand was received, but not recently" do
        redis.get("key")
        expect(raw_client).to receive(:close)
        client.disconnect_if_idle(Process.clock_gettime(Process::CLOCK_MONOTONIC) + 10)
      end
    end

    include_examples "disconnect_if_idle"

    context "with a cluster" do
      let(:redis) do
        allow_any_instance_of(RedisClient::Cluster::Node).to receive(:refetch_node_info_list).and_return(
          [RedisClient::Cluster::Node::Info.new(
            id: "id",
            node_key: "#{CanvasCache::Redis.redis._client.host}:#{CanvasCache::Redis.redis._client.port}",
            role: "master",
            primary_id: "-",
            slots: [[0, 16_383]]
          )]
        )
        Redis::Cluster.new(nodes: [CanvasCache::Redis.redis.id], connect_with_original_config: true)
      end

      let(:raw_client) do
        router = client.instance_variable_get(:@router)
        router.find_node(router.find_node_key(""))
      end

      include_examples "disconnect_if_idle"
    end
  end
end
