# frozen_string_literal: true

#
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

require_relative '../spec_helper'
require_relative '../../config/initializers/canvas_http'

describe "CanvasHttp Configuration" do
  after(:each) do
    CanvasHttpInitializer.configure_circuit_breaker!
  end

  it "has a circuit breaker mechamism" do
    CanvasHttp::CircuitBreaker.redis = ->{ Canvas.redis }
    CanvasHttp::CircuitBreaker.threshold = ->(_){ 0 }
    CanvasHttp::CircuitBreaker.interval = ->(_){ 1 }
    Setting.set('http_blocked_ip_ranges', '')
    allow(CanvasHttp).to receive(:connection_for_uri).and_raise(Net::OpenTimeout)
    begin
      CanvasHttp.get("some.url.com")
    rescue Net::OpenTimeout
      expect(CanvasHttp::CircuitBreaker.tripped?("some.url.com")).to eq(true)
    end
    expect { CanvasHttp.get("some.url.com") }.to raise_error(CanvasHttp::CircuitBreakerError)
  end
end
