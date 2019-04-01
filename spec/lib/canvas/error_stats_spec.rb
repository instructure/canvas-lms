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

require 'spec_helper'
require_dependency "canvas/error_stats"

module Canvas
  describe ErrorStats do
    describe ".capture" do
      before(:each) do
        allow(InstStatsd::Statsd).to receive(:increment)
      end
      let(:data){ {} }

      it "increments errors.all always" do
        expect(InstStatsd::Statsd).to receive(:increment).with("errors.all")
        described_class.capture("something", data)
      end

      it "increments the message name for a string" do
        expect(InstStatsd::Statsd).to receive(:increment).with("errors.something")
        described_class.capture("something", data)
      end

      it "increments the message name for a symbol" do
        expect(InstStatsd::Statsd).to receive(:increment).with("errors.something")
        described_class.capture(:something, data)
      end

      it "bumps the exception name for anything else" do
        expect(InstStatsd::Statsd).to receive(:increment).with("errors.StandardError")
        described_class.capture(StandardError.new, data)
      end
    end
  end
end
