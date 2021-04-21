# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require 'spec_helper'

describe CanvasHttp::CircuitBreaker do
  let(:redis_client_klass) do
    Class.new do
      def initialize(init_state = {})
        @state = init_state
        @timeouts = {}
      end

      # test harness methods
      def reset!
        @state = {}
        @timeouts = {}
      end

      def pass_time!(interval)
        keys = @timeouts.keys
        keys.each do |key|
          left = @timeouts[key] - interval
          if left <= 0
            @timeouts.delete(key)
            @state.delete(key)
          else
            @timeouts[key] = left
          end
        end
      end

      # Fake redis methods
      def get(key)
        @state[key]
      end

      def incr(key)
        @state[key] += 1
      end

      def setnx(key, value)
        @state[key] = value unless @state.keys.include?(key)
      end

      def setex(key, ttl, value)
        @state[key] = value
        @timeouts[key] = ttl
      end

      def expire(key, ttl)
        @timeouts[key] = ttl
      end
    end
  end

  let(:test_redis){ redis_client_klass.new }

  before(:each) do
    @old_redis = CanvasHttp::CircuitBreaker.redis
    test_redis.reset!
    CanvasHttp::CircuitBreaker.redis = -> { test_redis }
    CanvasHttp.logger = NullLogger.new
  end

  after(:each) do
    CanvasHttp::CircuitBreaker.redis = @old_redis
    CanvasHttp::CircuitBreaker.threshold = nil
    CanvasHttp.logger = nil
  end

  it "builds host-specific cache keys" do
    ckey = CanvasHttp::CircuitBreaker.tripped_key("cyoe.insops.com")
    expect(ckey).to eq("http_cb_tripped_cyoe.insops.com")
    ckey = CanvasHttp::CircuitBreaker.threshold_key("cyoe.insops.com")
    expect(ckey).to eq("http_cb_counter_cyoe.insops.com")
  end

  it "trips only after exceeding threshold" do
    domain = "dead.host.com"
    expect(CanvasHttp::CircuitBreaker.tripped?(domain)).to eq(false)
    CanvasHttp::CircuitBreaker::DEFAULT_THRESHOLD.times do
      CanvasHttp::CircuitBreaker.trip_if_necessary(domain)
    end
    expect(CanvasHttp::CircuitBreaker.tripped?(domain)).to eq(false)
    CanvasHttp::CircuitBreaker.trip_if_necessary(domain)
    expect(CanvasHttp::CircuitBreaker.tripped?(domain)).to eq(true)
  end

  it "goes away after interval" do
    domain = "dead.host.com"
    expect(CanvasHttp::CircuitBreaker.tripped?(domain)).to eq(false)
    (CanvasHttp::CircuitBreaker::DEFAULT_THRESHOLD * 2).times do
      CanvasHttp::CircuitBreaker.trip_if_necessary(domain)
    end
    expect(CanvasHttp::CircuitBreaker.tripped?(domain)).to eq(true)
    test_redis.pass_time!(CanvasHttp::CircuitBreaker::DEFAULT_INTERVAL)
    expect(CanvasHttp::CircuitBreaker.tripped?(domain)).to eq(false)
  end

  it "uses default values if the configuration block is broken" do
    CanvasHttp::CircuitBreaker.threshold = ->(domain){ nil }
    expect(CanvasHttp::CircuitBreaker.threshold("some.domain.com")).to eq(CanvasHttp::CircuitBreaker::DEFAULT_THRESHOLD)
  end
end