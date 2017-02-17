#
# Copyright (C) 2016 Instructure, Inc.
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

require_relative '../../spec_helper'

if Canvas.redis_enabled?
  describe Canvas::FailurePercentCounter do
    let(:counter) { Canvas::FailurePercentCounter.new(Canvas.redis, 'counter_spec', 1, 3) }

    it "increments the counter" do
      2.times { counter.increment_count }
      expect(counter.increment_count).to eq(3)
    end

    it "increments the failure counter" do
      counter.increment_failure
      expect(counter.increment_failure).to eq(2)
    end

    it "returns a 0 failure rate when there is no data" do
      expect(counter.failure_rate).to eq(0.0)
    end

    it "returns a 0 failure rate when there aren't enough samples" do
      counter.increment_count
      counter.increment_failure
      expect(counter.failure_rate).to eq(0.0)
    end

    it "returns a proper failure rate when there are enough samples" do
      4.times { counter.increment_count }
      2.times { counter.increment_failure }
      expect(counter.failure_rate).to eq(0.5)
    end
  end
end
