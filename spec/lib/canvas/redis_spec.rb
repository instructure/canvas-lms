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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

if Canvas.redis_enabled?
describe "Canvas::Redis" do
  it "doesn't marshall" do
    Canvas.redis.set('test', 1)
    expect(Canvas.redis.get('test')).to eq '1'
  end

  describe "locking" do
    it "should succeed if the lock isn't taken" do
      expect(Canvas::Redis.lock('test1')).to eq true
      expect(Canvas::Redis.lock('test2')).to eq true
    end

    it "should fail if the lock is taken" do
      expect(Canvas::Redis.lock('test1')).to eq true
      expect(Canvas::Redis.lock('test1')).to eq false
      expect(Canvas::Redis.unlock('test1')).to eq true
      expect(Canvas::Redis.lock('test1')).to eq true
    end

    it "should live forever if no expire time is given" do
      expect(Canvas::Redis.lock('test1')).to eq true
      expect(Canvas.redis.ttl(Canvas::Redis.lock_key('test1'))).to eq -1
    end

    it "should set the expire time if given" do
      expect(Canvas::Redis.lock('test1', 15)).to eq true
      ttl = Canvas.redis.ttl(Canvas::Redis.lock_key('test1'))
      expect(ttl).to be > 0
      expect(ttl).to be <= 15
    end
  end

  describe "exceptions" do
    before do
      Canvas::Redis.patch
    end

    after do
      Canvas::Redis.reset_redis_failure
    end

    it "should protect against errnos" do
      expect(Canvas.redis._client).to receive(:write).and_raise(Errno::ETIMEDOUT).once
      expect(Canvas.redis.set('blah', 'blah')).to eq nil
    end

    it "should protect against max # of client errors" do
      expect(Canvas.redis._client).to receive(:write).and_raise(Redis::CommandError.new("ERR max number of clients reached")).once
      expect(Canvas.redis.set('blah', 'blah')).to eq nil
    end

    it "should pass through other command errors" do
      expect(CanvasStatsd::Statsd).to receive(:increment).never

      expect(Canvas.redis._client).to receive(:write).and_raise(Redis::CommandError.new("NOSCRIPT No matching script. Please use EVAL.")).once
      expect { Canvas.redis.evalsha('xxx') }.to raise_error(Redis::CommandError)

      expect(Canvas.redis._client).to receive(:write).and_raise(Redis::CommandError.new("ERR no such key")).once
      expect { Canvas.redis.get('no-such-key') }.to raise_error(Redis::CommandError)
    end

    describe "redis failure" do
      let(:cache) { ActiveSupport::Cache::RedisStore.new(['redis://localhost:1234']) }

      before do
        allow(cache.data._client).to receive(:ensure_connected).and_raise(Redis::TimeoutError)
      end

      it "should fail if not ignore_redis_failures" do
        Setting.set('ignore_redis_failures', 'false')
        expect {
          enable_cache(cache) {
            expect(Rails.cache.read('blah')).to eq nil
          }
        }.to raise_error(Redis::TimeoutError)
      end

      it "should not fail cache.read" do
        enable_cache(cache) do
          expect(Rails.cache.read('blah')).to eq nil
        end
      end

      it "should not call redis again after an error" do
        enable_cache(cache) do
          expect(Rails.cache.read('blah')).to eq nil
          # call again, the .once means that if it hits Redis::Client again it'll fail
          expect(Rails.cache.read('blah')).to eq nil
        end
      end

      it "should not fail cache.write" do
        enable_cache(cache) do
          expect(Rails.cache.write('blah', 'someval')).to eq nil
        end
      end

      it "should not fail cache.delete" do
        enable_cache(cache) do
          expect(Rails.cache.delete('blah')).to eq 0
        end
      end

      it "should not fail cache.delete for a ring" do
        enable_cache(ActiveSupport::Cache::RedisStore.new(['redis://localhost:1234', 'redis://localhost:4567'])) do
          expect(Rails.cache.delete('blah')).to eq 0
        end
      end

      it "should not fail cache.exist?" do
        enable_cache(cache) do
          expect(Rails.cache.exist?('blah')).to be_falsey
        end
      end

      it "should not fail cache.delete_matched" do
        enable_cache(cache) do
          expect(Rails.cache.delete_matched('blah')).to eq false
        end
      end

      it "should fail separate servers separately" do
        cache = ActiveSupport::Cache::RedisStore.new([Canvas.redis.id, 'redis://nonexistent:1234/0'])
        client = cache.data
        key2 = 2
        while client.node_for('1') == client.node_for(key2.to_s)
          key2 += 1
        end
        key2 = key2.to_s
        expect(client.node_for('1')).not_to eq client.node_for(key2)
        expect(client.nodes.last.id).to eq 'redis://nonexistent:1234/0'
        expect(client.nodes.last._client).to receive(:ensure_connected).and_raise(Redis::TimeoutError).once

        cache.write('1', true, :use_new_rails => false)
        cache.write(key2, true, :use_new_rails => false)
        # one returned nil, one returned true; we don't know which one which key ended up on
        expect([
          cache.fetch('1', :use_new_rails => false),
          cache.fetch(key2, :use_new_rails => false)
        ].compact).to eq [true]
      end

      it "should not fail raw redis commands" do
        expect(Canvas.redis._client).to receive(:ensure_connected).and_raise(Redis::TimeoutError).once
        expect(Canvas.redis.setnx('my_key', 5)).to eq nil
      end

      it "distinguishes between failure and not exists for set nx" do
        Canvas.redis.del('my_key')
        expect(Canvas.redis.set('my_key', 5, nx: true)).to eq true
        expect(Canvas.redis.set('my_key', 5, nx: true)).to eq false
        expect(Canvas.redis._client).to receive(:ensure_connected).and_raise(Redis::TimeoutError).once
        expect(Canvas.redis.set('my_key', 5, nx: true)).to eq nil
      end

    end
  end

  describe "json logging" do
    let(:key) { 'mykey' }
    let(:key2) { 'mykey2' }
    let(:val) { 'myvalue' }
    before(:once) { Setting.set('redis_log_style', 'json') }
    # cache to avoid capturing a log line for db lookup
    before(:each) { Canvas::Redis.log_style }

    def json_logline(get = :shift)
      # drop the non-json logging at the start of the line
      JSON.parse(Rails.logger.captured_messages.send(get).match(/\{.*/)[0])
    end

    it "should log information on the redis request" do
      Rails.logger.capture_messages do
        Canvas.redis.set(key, val)
        message = json_logline
        expect(message["message"]).to eq("redis_request")
        expect(message["command"]).to eq("set")
        expect(message["key"]).to eq("mykey")
        expect(message["request_size"]).to eq((key+val).size)
        expect(message["response_size"]).to eq(2) # "OK"
        expect(message["host"]).not_to be_nil
        expect(message["request_time_ms"]).to be_a(Float)
      end
    end

    it "should not log the lua eval code" do
      Rails.logger.capture_messages do
        Canvas.redis.eval('local a = 1')
        message = json_logline
        expect(message["key"]).to be_nil
      end
    end

    it "should log error on redis error response" do
      Rails.logger.capture_messages do
        expect { Canvas.redis.eval('totes not lua') }.to raise_error(Redis::CommandError)
        message = json_logline
        expect(message["response_size"]).to eq(0)
        expect(message["error"]).to be_a(String)
      end
    end

    context "rails caching" do
      let(:cache) do
        ActiveSupport::Cache::RedisStore.new([]).tap do |cache|
          cache.instance_variable_set(:@data, Canvas.redis.__getobj__)
        end
      end

      it "should log the cache fetch block generation time" do
        begin
          Timecop.safe_mode = false
          Timecop.freeze
          Rails.logger.capture_messages do
            # make sure this works with fetching nested fetches
            cache.fetch(key, force: true) do
              val = "a1"
              val << cache.fetch(key2, force: true) do
                Timecop.travel(Time.zone.now + 1.second)
                "b1"
              end
              Timecop.travel(Time.zone.now + 2.seconds)
              val << "a2"
            end
            outer_message = json_logline(:pop)
            expect(outer_message["command"]).to eq("set")
            expect(outer_message["key"]).to be_ends_with(key)
            expect(outer_message["request_time_ms"]).to be_a(Float)
            # 3000 (3s) == 2s outer fetch + 1s inner fetch
            expect(outer_message["generate_time_ms"]).to be_within(500).of(3000)

            inner_message = json_logline(:pop)
            expect(inner_message["command"]).to eq("set")
            expect(inner_message["key"]).to be_ends_with(key2)
            expect(inner_message["request_time_ms"]).to be_a(Float)
            expect(inner_message["generate_time_ms"]).to be_within(500).of(1000)
          end
        ensure
          Timecop.return
          Timecop.safe_mode = true
        end
      end

      it "should log zero response size on cache miss" do
        cache.delete(key)
        Rails.logger.capture_messages do
          expect(cache.read(key)).to be_nil
          message = json_logline(:pop)
          expect(message["command"]).to eq("get")
          expect(message["response_size"]).to eq(0)
        end
      end
    end
  end

  it "should log compactly by default on the redis request" do
    # cache to avoid capturing a log line for db lookup
    Canvas::Redis.log_style
    Rails.logger.capture_messages do
      Canvas.redis.set('mykey', 'myvalue')
      msg = Rails.logger.captured_messages.first
      expect(msg).to match(/Redis \(\d+\.\d+ms\) set mykey \[.*\]/)
    end
  end

  it "should allow disabling redis logging" do
    Setting.set('redis_log_style', 'off')
    # cache to avoid capturing a log line for db lookup
    Canvas::Redis.log_style
    Rails.logger.capture_messages do
      Canvas.redis.set('mykey', 'myvalue')
      expect(Rails.logger.captured_messages).to be_empty
    end
  end

  describe "Canvas::RedisWrapper" do
    it "should wrap redis connections" do
      expect(Canvas.redis.class).to eq Canvas::RedisWrapper
    end

    it "should raise on unsupported commands" do
      expect { Canvas.redis.keys }.to raise_error(Canvas::Redis::UnsupportedRedisMethod)
    end
  end
end
end
