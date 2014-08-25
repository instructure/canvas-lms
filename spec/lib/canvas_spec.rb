#
# Copyright (C) 2011 - 2013 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe Canvas do
  describe ".timeout_protection" do
    it "should wrap the block in a timeout" do
      Setting.set("service_generic_timeout", "2")
      Timeout.expects(:timeout).with(2).yields
      ran = false
      Canvas.timeout_protection("spec") { ran = true }
      ran.should == true

      # service-specific timeout
      Setting.set("service_spec_timeout", "1")
      Timeout.expects(:timeout).with(1).yields
      ran = false
      Canvas.timeout_protection("spec") { ran = true }
      ran.should == true
    end

    it "should raise on timeout if raise_on_timeout option is specified" do
      Timeout.expects(:timeout).raises(Timeout::Error)
      lambda { Canvas.timeout_protection("spec", raise_on_timeout: true) {} }.should raise_error(Timeout::Error)
    end

    it "should use the timeout argument over the generic default" do
      Timeout.expects(:timeout).with(23)
      Canvas.timeout_protection("foo", fallback_timeout_length: 23)
    end

    it "should use the settings timeout over the timeout argument" do
      Setting.set("service_foo_timeout", "1")
      Timeout.expects(:timeout).with(1)
      Canvas.timeout_protection("foo", fallback_timeout_length: 23)
    end

    if Canvas.redis_enabled?
      it "should skip calling the block after X failures" do
        Setting.set("service_spec_cutoff", "2")
        Timeout.expects(:timeout).with(15).twice.raises(Timeout::Error)
        Canvas.timeout_protection("spec") {}
        Canvas.timeout_protection("spec") {}
        ran = false
        # third time, won't call timeout
        Canvas.timeout_protection("spec") { ran = true }
        ran.should == false
        # verify the redis key has a ttl
        key = "service:timeouts:spec"
        Canvas.redis.get(key).should == "2"
        Canvas.redis.ttl(key).should be_present
        # delete the redis key and it'll try again
        Canvas.redis.del(key)
        Timeout.expects(:timeout).with(15).yields
        Canvas.timeout_protection("spec") { ran = true }
        ran.should == true
      end

      it "should raise on cutoff if raise_on_timeout option is specified" do
        Canvas.redis.set("service:timeouts:spec", 42)
        lambda { Canvas.timeout_protection("spec", raise_on_timeout: true) {} }.should raise_error(Timeout::Error)
        Canvas.redis.get("service:timeouts:spec").should == "42"
      end
    end
  end

  if Canvas.redis_enabled?
    describe ".short_circuit_timeout" do
      it "should wrap the block in a timeout" do
        Timeout.expects(:timeout).with(15).yields
        ran = false
        Canvas.short_circuit_timeout(Canvas.redis, "spec", 15, 2, 1) { ran = true }
        ran.should == true
      end

      it "should raise Timeout::Error on timeout" do
        Timeout.expects(:timeout).raises(Timeout::Error)
        lambda { Canvas.short_circuit_timeout(Canvas.redis, "spec", 15, 2, 1) {} }.should raise_error(Timeout::Error)
      end

      it "should skip calling the block after X failures" do
        Timeout.expects(:timeout).with(15).twice.raises(Timeout::Error)
        lambda { Canvas.short_circuit_timeout(Canvas.redis, "timeouts:spec", 15, 2, 1) {} }.should raise_error(Timeout::Error)
        lambda { Canvas.short_circuit_timeout(Canvas.redis, "timeouts:spec", 15, 2, 1) {} }.should raise_error(Timeout::Error)
        ran = false
        # third time, won't call timeout
        lambda { Canvas.short_circuit_timeout(Canvas.redis, "timeouts:spec", 15, 2, 1) { ran = true } }.should raise_error(Timeout::Error)
        ran.should == false
        # verify the redis key has a ttl
        key = "timeouts:spec"
        Canvas.redis.get(key).should == "2"
        Canvas.redis.ttl(key).should be_present
        # delete the redis key and it'll try again
        Canvas.redis.del(key)
        Timeout.expects(:timeout).with(15).yields
        Canvas.short_circuit_timeout(Canvas.redis, "timeouts:spec", 15, 2, 1) { ran = true }
        ran.should == true
      end

      it "should raise TimeoutCutoff when the cutoff is reached" do
        Canvas.redis.set("timeouts:spec", 42)
        lambda { Canvas.short_circuit_timeout(Canvas.redis, "timeouts:spec", 15, 2, 1) { ran = true} }.should raise_error(Canvas::TimeoutCutoff)
        Canvas.redis.get("timeouts:spec").should == "42"
      end
    end
  end

  describe ".cache_stores" do
    before do
      @old_cache_stores = Canvas.instance_variable_get(:@cache_stores)
      Canvas.instance_variable_set(:@cache_stores, nil)
    end

    after do
      Canvas.instance_variable_set(:@cache_stores, @old_cache_stores)
    end

    it "should pass through string links" do
      ConfigFile.stubs(:load).returns('other' => { 'cache_store' => 'redis_store' }, 'db1' => 'other')
      Canvas.cache_stores.should == { 'other' => [ :redis_store, nil ], 'db1' => 'other', 'test' => :null_store }
    end

  end
end
