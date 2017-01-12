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
      expect(ran).to eq true

      # service-specific timeout
      Setting.set("service_spec_timeout", "1")
      Timeout.expects(:timeout).with(1).yields
      ran = false
      Canvas.timeout_protection("spec") { ran = true }
      expect(ran).to eq true
    end

    it "should raise on timeout if raise_on_timeout option is specified" do
      Timeout.expects(:timeout).raises(Timeout::Error)
      expect { Canvas.timeout_protection("spec", raise_on_timeout: true) {} }.to raise_error(Timeout::Error)
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
        expect(ran).to eq false
        # verify the redis key has a ttl
        key = "service:timeouts:spec:error_count"
        expect(Canvas.redis.get(key)).to eq "2"
        expect(Canvas.redis.ttl(key)).to be_present
        # delete the redis key and it'll try again
        Canvas.redis.del(key)
        Timeout.expects(:timeout).with(15).yields
        Canvas.timeout_protection("spec") { ran = true }
        expect(ran).to eq true
      end

      it "should raise on cutoff if raise_on_timeout option is specified" do
        key = "service:timeouts:spec:error_count"
        Canvas.redis.set(key, 42)
        expect { Canvas.timeout_protection("spec", raise_on_timeout: true) {} }.
          to raise_error(Timeout::Error)
        expect(Canvas.redis.get(key)).to eq "42"
      end

      it "calls percent_short_circuit_timeout when set to do so" do
        Setting.set("service_spec_timeout_protection_method", "percentage")
        Canvas.expects(:percent_short_circuit_timeout).once
        Canvas.timeout_protection("spec") {}
      end
    end
  end

  if Canvas.redis_enabled?
    describe ".short_circuit_timeout" do
      it "should wrap the block in a timeout" do
        Timeout.expects(:timeout).with(15).yields
        ran = false
        Canvas.short_circuit_timeout(Canvas.redis, "spec", 15) { ran = true }
        expect(ran).to eq true
      end

      it "should skip calling the block after X failures" do
        Setting.set("service_spec_cutoff", "2")
        Timeout.expects(:timeout).with(15).twice.raises(Timeout::Error)
        expect { Canvas.short_circuit_timeout(Canvas.redis, "spec", 15) {} }.
          to raise_error(Timeout::Error)
        expect { Canvas.short_circuit_timeout(Canvas.redis, "spec", 15) {} }.
          to raise_error(Timeout::Error)
        ran = false
        # third time, won't call timeout
        expect { Canvas.short_circuit_timeout(Canvas.redis, "spec", 15) { ran = true } }.
          to raise_error(Timeout::Error)
        expect(ran).to eq false
        # verify the redis key has a ttl
        key = "service:timeouts:spec:error_count"
        expect(Canvas.redis.get(key)).to eq "2"
        expect(Canvas.redis.ttl(key)).to be_present
        # delete the redis key and it'll try again
        Canvas.redis.del(key)
        Timeout.expects(:timeout).with(15).yields
        Canvas.short_circuit_timeout(Canvas.redis, "spec", 15) { ran = true }
        expect(ran).to eq true
      end

      it "should raise TimeoutCutoff when the cutoff is reached" do
        Setting.set("service_spec_cutoff", "2")
        key = "service:timeouts:spec:error_count"
        Canvas.redis.set(key, 42)
        expect { Canvas.short_circuit_timeout(Canvas.redis, "spec", 15) { } }.
          to raise_error(Canvas::TimeoutCutoff)
        expect(Canvas.redis.get(key)).to eq "42"
      end
    end

    describe ".percent_short_circuit_timeout" do
      it "should raise TimeoutCutoff when the protection key is present" do
        Canvas.redis.set("service:timeouts:spec:percent_counter:protection_activated", "true")
        Canvas.redis.expire("service:timeouts:spec:percent_counter:protection_activated", 1)
        expect { Canvas.percent_short_circuit_timeout(Canvas.redis, "spec", 15) {}}.
          to raise_error(Canvas::TimeoutCutoff)
      end

      it "raise TimeoutCutoff when the failure rate is too high" do
        counter = Canvas::FailurePercentCounter.new(Canvas.redis,
          "service:timeouts:spec:percent_counter")
        counter.expects(:failure_rate).returns(0.2)
        Canvas::FailurePercentCounter.expects(:new).returns(counter)
        expect { Canvas.percent_short_circuit_timeout(Canvas.redis, "spec", 15) {}}.
          to raise_error(Canvas::TimeoutCutoff)
      end

      it "wraps the block in a timeout" do
        Timeout.expects(:timeout).with(15).yields
        ran = false
        Canvas.percent_short_circuit_timeout(Canvas.redis, "spec", 15) { ran = true }
        expect(ran).to eq true
      end

      it "increments the counter when the block is called" do
        counter = Canvas::FailurePercentCounter.new(Canvas.redis,
          "service:timeouts:spec:percent_counter")
        counter.expects(:failure_rate).returns(0.0)
        counter.expects(:increment_count)
        Canvas::FailurePercentCounter.expects(:new).returns(counter)
        Canvas.percent_short_circuit_timeout(Canvas.redis, "spec", 15) { }
      end

      it "raises Timeout::Error on timeout" do
        Timeout.expects(:timeout).raises(Timeout::Error)
        expect { Canvas.percent_short_circuit_timeout(Canvas.redis, "spec", 15) {} }.
          to raise_error(Timeout::Error)
      end

      it "increments the failure count on timeout" do
        Timeout.expects(:timeout).raises(Timeout::Error)
        counter = Canvas::FailurePercentCounter.new(Canvas.redis,
          "service:timeouts:spec:percent_counter")
        counter.expects(:failure_rate).returns(0.0)
        counter.expects(:increment_count)
        counter.expects(:increment_failure)
        Canvas::FailurePercentCounter.expects(:new).returns(counter)
        expect { Canvas.percent_short_circuit_timeout(Canvas.redis, "spec", 15) {} }.
          to raise_error(Timeout::Error)
      end

      it "sets the protection activated key if failure rate too high" do
        counter = Canvas::FailurePercentCounter.new(Canvas.redis,
          "service:timeouts:spec:percent_counter")
        counter.expects(:failure_rate).returns(0.2)
        Canvas::FailurePercentCounter.expects(:new).returns(counter)
        expect { Canvas.percent_short_circuit_timeout(Canvas.redis, "spec", 15) {} }.
          to raise_error(Timeout::Error)
        key = "service:timeouts:spec:percent_counter:protection_activated"
        expect(Canvas.redis.get(key)).to eq "true"
        expect(Canvas.redis.ttl(key)).to be_present
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
      ConfigFile.stubs(:load).returns('other' => { 'cache_store' => 'redis_store', 'servers' => ['localhost:6379'] }, 'db1' => 'other')
      stores = Canvas.cache_stores
      expect(stores.keys.sort).to eq ['db1', 'other', 'test']
      expect(stores['other']).to be_a(Array)
      expect(stores['other'].first).to eq :redis_store
      expect(stores['db1']).to eq 'other'
      expect(stores['test']).to eq :null_store
    end

  end
end
