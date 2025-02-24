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
  class FakeErrorStatsError < StandardError; end

  class OuterErrorStatsError < StandardError; end

  describe ErrorStats do
    describe ".capture" do
      def a_regrettable_method
        raise FakeErrorStatsError, "you asked for this"
      rescue FakeErrorStatsError
        raise OuterErrorStatsError, "so it's happening"
      end

      before do
        allow(InstStatsd::Statsd).to receive(:increment)
      end

      let(:data) { {} }

      it "increments the error level by default" do
        described_class.capture("something", data)
        expect(InstStatsd::Statsd).to have_received(:increment) do |key, data|
          expect(key).to eq("errors.error")
          expect(data[:tags][:category]).to eq("something")
        end
      end

      it "uses the exception name for the category tag" do
        described_class.capture(StandardError.new, data, :warn)
        expect(InstStatsd::Statsd).to have_received(:increment) do |key, data|
          expect(key).to eq("errors.warn")
          expect(data[:tags][:category]).to eq("StandardError")
        end
      end

      it "increments the inner exception too" do
        got_inner = false
        got_outer = false
        allow(InstStatsd::Statsd).to receive(:increment) do |_key, data|
          cat = data[:tags][:category]
          got_inner = true if cat == "Canvas::FakeErrorStatsError"
          got_outer = true if cat == "Canvas::OuterErrorStatsError"
        end
        begin
          a_regrettable_method
          raise "How did we get here? More regrettable than expected..."
        rescue OuterErrorStatsError => e
          described_class.capture(e, {}, :warn)
        end
        expect(got_inner).to be_truthy
        expect(got_outer).to be_truthy
      end
    end
  end
end
