#
# Copyright (C) 2011 Instructure, Inc.
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
      Redis::Client.any_instance.expects(:write).raises(Errno::ETIMEDOUT).once
      expect(Canvas.redis.set('blah', 'blah')).to eq nil
    end

    it "should protect against max # of client errors" do
      Redis::Client.any_instance.expects(:write).raises(Redis::CommandError.new("ERR max number of clients reached")).once
      expect(Canvas.redis.set('blah', 'blah')).to eq nil
    end

    it "should pass through other command errors" do
      CanvasStatsd::Statsd.expects(:increment).never

      Redis::Client.any_instance.expects(:write).raises(Redis::CommandError.new("NOSCRIPT No matching script. Please use EVAL.")).once
      expect { Canvas.redis.evalsha('xxx') }.to raise_error(Redis::CommandError)

      Redis::Client.any_instance.expects(:write).raises(Redis::CommandError.new("ERR no such key")).once
      expect { Canvas.redis.get('no-such-key') }.to raise_error(Redis::CommandError)
    end

    describe "redis failure" do
      before do
        Redis::Client.any_instance.expects(:ensure_connected).raises(Redis::TimeoutError).once
      end

      it "should fail if not ignore_redis_failures" do
        Setting.set('ignore_redis_failures', 'false')
        expect {
          enable_cache(ActiveSupport::Cache::RedisStore.new(['redis://localhost:1234'])) {
            expect(Rails.cache.read('blah')).to eq nil
          }
        }.to raise_error(Redis::TimeoutError)
      end

      it "should not fail cache.read" do
        enable_cache(ActiveSupport::Cache::RedisStore.new(['redis://localhost:1234'])) do
          expect(Rails.cache.read('blah')).to eq nil
        end
      end

      it "should not call redis again after an error" do
        enable_cache(ActiveSupport::Cache::RedisStore.new(['redis://localhost:1234'])) do
          expect(Rails.cache.read('blah')).to eq nil
          # call again, the .once means that if it hits Redis::Client again it'll fail
          expect(Rails.cache.read('blah')).to eq nil
        end
      end

      it "should not fail cache.write" do
        enable_cache(ActiveSupport::Cache::RedisStore.new(['redis://localhost:1234'])) do
          expect(Rails.cache.write('blah', 'someval')).to eq nil
        end
      end

      it "should not fail cache.delete" do
        enable_cache(ActiveSupport::Cache::RedisStore.new(['redis://localhost:1234'])) do
          expect(Rails.cache.delete('blah')).to eq 0
        end
      end

      it "should not fail cache.delete for a ring" do
        enable_cache(ActiveSupport::Cache::RedisStore.new(['redis://localhost:1234', 'redis://localhost:4567'])) do
          expect(Rails.cache.delete('blah')).to eq 0
        end
      end

      it "should not fail cache.exist?" do
        enable_cache(ActiveSupport::Cache::RedisStore.new(['redis://localhost:1234'])) do
          expect(Rails.cache.exist?('blah')).to be_falsey
        end
      end

      it "should not fail cache.delete_matched" do
        enable_cache(ActiveSupport::Cache::RedisStore.new(['redis://localhost:1234'])) do
          expect(Rails.cache.delete_matched('blah')).to eq false
        end
      end

      it "should fail separate servers separately" do
        skip("fails in rails 4 with rails 3 cache shim") unless CANVAS_RAILS3
        Redis::Client.any_instance.unstub(:ensure_connected)

        cache = ActiveSupport::Cache::RedisStore.new([Canvas.redis.id, 'redis://nonexistent:1234/0'])
        client = cache.instance_variable_get(:@data)
        key2 = 2
        while client.node_for('1') == client.node_for(key2.to_s)
          key2 += 1
        end
        key2 = key2.to_s
        expect(client.node_for('1')).not_to eq client.node_for(key2)
        expect(client.nodes.last.id).to eq 'redis://nonexistent:1234/0'
        client.nodes.last.client.expects(:ensure_connected).raises(Redis::TimeoutError).once

        cache.write('1', true)
        cache.write(key2, true)
        # one returned nil, one returned true; we don't know which one which key ended up on
        expect([cache.fetch('1'), cache.fetch(key2)].compact).to eq [true]
      end

      it "should not fail raw redis commands" do
        expect(Canvas.redis.setnx('my_key', 5)).to eq nil
      end
    end
  end

  describe "Canvas::RedisWrapper" do
    it "should wrap redis connections" do
      expect(Canvas.redis.class).to eq Canvas::RedisWrapper
    end

    it "should raise on unsupported commands" do
      expect { Canvas.redis.keys }.to raise_error(Canvas::RedisWrapper::UnsupportedRedisMethod)
    end
  end
end
end
