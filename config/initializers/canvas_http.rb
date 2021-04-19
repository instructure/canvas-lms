# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

CanvasHttp.open_timeout = -> { Setting.get('http_open_timeout', 5).to_f }
CanvasHttp.read_timeout = -> { Setting.get('http_read_timeout', 30).to_f }
CanvasHttp.logger = -> { Rails.logger }
CanvasHttp.blocked_ip_filters = -> { Setting.get('http_blocked_ip_ranges', '127.0.0.1/8').split(/,/).presence }

module CanvasHttpInitializer
  def self.configure_circuit_breaker!
    # need some place to store circuit breaker information so we don't 
    # have to have each process store it's own circuit breaker
    # state
    CanvasHttp::CircuitBreaker.redis = lambda {
      return MultiCache.cache.redis if MultiCache.cache.respond_to?(:redis)
      return Canvas.redis if Canvas.redis_enabled?
      nil
    }

    # how many failures for a domain trips the circuit breaker
    CanvasHttp::CircuitBreaker.threshold = lambda do |domain|
      (Setting.get("http_cb_#{domain}_threshold", nil) || 
        Setting.get("http_cb_generic_threshold", CanvasHttp::CircuitBreaker::DEFAULT_THRESHOLD)).to_i
    end

    # how long (in seconds) to debounce counting failures approaching the threshold
    CanvasHttp::CircuitBreaker.window = lambda do |domain|
      (Setting.get("http_cb_#{domain}_window", nil) ||
        Setting.get('http_cb_generic_window', CanvasHttp::CircuitBreaker::DEFAULT_WINDOW)).to_i
    end

    # how long (in seconds) to just fail before trying to hit a given target again
    CanvasHttp::CircuitBreaker.interval = lambda do |domain|
      (Setting.get("http_cb_#{domain}_interval", nil) ||
        Setting.get('http_cb_generic_interval', CanvasHttp::CircuitBreaker::DEFAULT_INTERVAL)).to_i
    end
  end
end

CanvasHttpInitializer.configure_circuit_breaker!
