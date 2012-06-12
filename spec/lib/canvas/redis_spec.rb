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

  describe "redis failure" do
    before do
      Canvas::Redis.patch
      Redis::Client.any_instance.expects(:ensure_connected).raises(Redis::TimeoutError).once
    end

    after do
      Canvas::Redis.reset_redis_failure
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
        Rails.cache.delete('blah').should == nil
      end
    end

    it "should not fail cache.exist?" do
      enable_cache(ActiveSupport::Cache::RedisStore.new(['redis://localhost:1234'])) do
        Rails.cache.exist?('blah').should == nil
      end
    end

    it "should not fail cache.delete_matched" do
      enable_cache(ActiveSupport::Cache::RedisStore.new(['redis://localhost:1234'])) do
        Rails.cache.delete_matched('blah').should == false
      end
    end

    it "should not fail raw redis commands" do
      Canvas.redis.setnx('my_key', 5).should == nil
    end
  end
end
end
