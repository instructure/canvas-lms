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

module Canvas
  # TODO: Leaving one spec in here to make sure the shim
  # works until we've successfully re-pointed all
  # callsites to "CanvasErrors"
  describe Errors do
    error_testing_class = Class.new do
      attr_accessor :exception, :details, :level

      def register!
        target = self
        Canvas::Errors.register!(:test_thing) do |e, d, l|
          target.exception = e
          target.details = d
          target.level = l
          "ERROR_BLOCK_RESPONSE"
        end
      end
    end

    before do
      @old_registry = described_class.instance_variable_get(:@registry)
      described_class.clear_callback_registry!
      @error_harness = error_testing_class.new
      @error_harness.register!
    end

    after do
      described_class.instance_variable_set(:@registry, @old_registry)
    end

    let(:error) { double("Some Error", backtrace: []) }

    describe ".capture_exception" do
      it "tags with the exception type and default level" do
        Canvas::Errors.capture_exception(:core_meltdown, error)
        expect(@error_harness.exception).to eq(error)
        expect(@error_harness.details[:tags][:type]).to eq("core_meltdown")
        expect(@error_harness.level).to eq(:error)
      end
    end
  end
end
