# frozen_string_literal: true

# Copyright (C) 2021 - present Instructure, Inc.
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

require "spec_helper"

module DynamicSettings
  RSpec.describe CircuitBreaker do
    let(:circuit_breaker) { CircuitBreaker.new }

    it "is not initially tripped" do
      expect(circuit_breaker).not_to be_tripped
    end

    it "trips" do
      circuit_breaker.trip
      expect(circuit_breaker).to be_tripped
    end

    it "untrips after time passes" do
      circuit_breaker.trip
      now = Time.now.utc
      allow(Time).to receive(:now).and_return(now + 5.minutes)
      expect(circuit_breaker).not_to be_tripped
    end
  end
end
