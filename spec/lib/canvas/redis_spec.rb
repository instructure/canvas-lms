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
      Canvas::Redis.lock('test1').should == true
      Canvas::Redis.lock('test2').should == true
    end

    it "should fail if the lock is taken" do
      Canvas::Redis.lock('test1').should == true
      Canvas::Redis.lock('test1').should == false
      Canvas::Redis.unlock('test1').should == true
      Canvas::Redis.lock('test1').should == true
    end

    it "should live forever if no expire time is given" do
      Canvas::Redis.lock('test1').should == true
      Canvas.redis.ttl(Canvas::Redis.lock_key('test1')).should == -1
    end

    it "should set the expire time if given" do
      Canvas::Redis.lock('test1', 15).should == true
      ttl = Canvas.redis.ttl(Canvas::Redis.lock_key('test1'))
      ttl.should > 0
      ttl.should <= 15
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
      Canvas.redis.set('blah', 'blah').should == nil
    end

    it "should protect against ERR command errors" do
      Redis::Client.any_instance.expects(:write).raises(Redis::CommandError.new("ERR max number of clients reached")).once
      Canvas.redis.read('blah').should == nil
    end

    it "should pass through other command errors" do
      Redis::Client.any_instance.expects(:write).raises(Redis::CommandError.new("NOSCRIPT No matching script. Please use EVAL.")).once
      expect { Canvas.redis.evalsha('xxx') }.to raise_error(Redis::CommandError)
    end

    describe "redis failure" do
      before do
        Redis::Client.any_instance.expects(:ensure_connected).raises(Redis::TimeoutError).once
      end

      it "should fail if not ignore_redis_failures" do
        Setting.set('ignore_redis_failures', 'false')
        expect {
          enable_cache(ActiveSupport::Cache::RedisStore.new(['redis://localhost:1234'])) {
            Rails.cache.read('blah').should == nil
          }
        }.to raise_error(Redis::TimeoutError)
      end

      it "should not fail cache.read" do
        enable_cache(ActiveSupport::Cache::RedisStore.new(['redis://localhost:1234'])) do
          Rails.cache.read('blah').should == nil
        end
      end

      it "should not call redis again after an error" do
        enable_cache(ActiveSupport::Cache::RedisStore.new(['redis://localhost:1234'])) do
          Rails.cache.read('blah').should == nil
          # call again, the .once means that if it hits Redis::Client again it'll fail
          Rails.cache.read('blah').should == nil
        end
      end

      it "should not fail cache.write" do
        enable_cache(ActiveSupport::Cache::RedisStore.new(['redis://localhost:1234'])) do
          Rails.cache.write('blah', 'someval').should == nil
        end
      end

      it "should not fail cache.delete" do
        enable_cache(ActiveSupport::Cache::RedisStore.new(['redis://localhost:1234'])) do
          Rails.cache.delete('blah').should == 0
        end
      end

      it "should not fail cache.delete for a ring" do
        enable_cache(ActiveSupport::Cache::RedisStore.new(['redis://localhost:1234', 'redis://localhost:4567'])) do
          Rails.cache.delete('blah').should == 0
        end
      end

      it "should not fail cache.exist?" do
        enable_cache(ActiveSupport::Cache::RedisStore.new(['redis://localhost:1234'])) do
          Rails.cache.exist?('blah').should be_false
        end
      end

      it "should not fail cache.delete_matched" do
        enable_cache(ActiveSupport::Cache::RedisStore.new(['redis://localhost:1234'])) do
          Rails.cache.delete_matched('blah').should == false
        end
      end

      it "should fail separate servers separately" do
        Redis::Client.any_instance.unstub(:ensure_connected)

        cache = ActiveSupport::Cache::RedisStore.new([Canvas.redis.id, 'redis://nonexistent:1234/0'])
        client = cache.instance_variable_get(:@data)
        key2 = 2
        while client.node_for('1') == client.node_for(key2.to_s)
          key2 += 1
        end
        key2 = key2.to_s
        client.node_for('1').should_not == client.node_for(key2)
        client.nodes.last.id.should == 'redis://nonexistent:1234/0'
        client.nodes.last.client.expects(:ensure_connected).raises(Redis::TimeoutError).once

        cache.write('1', true)
        cache.write(key2, true)
        # one returned nil, one returned true; we don't know which one which key ended up on
        [cache.fetch('1'), cache.fetch(key2)].compact.should == [true]
      end

      it "should not fail raw redis commands" do
        Canvas.redis.setnx('my_key', 5).should == nil
      end
    end
  end
end
end
