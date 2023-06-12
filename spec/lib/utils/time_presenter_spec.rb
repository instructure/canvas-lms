# frozen_string_literal: true

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
# Copyright (C) 2011 Instructure, Inc.
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

require_relative "../../spec_helper"

module Utils
  describe TimePresenter do
    describe "#as_string" do
      before do
        @zone = Time.zone
        Time.zone = "Mountain Time (US & Canada)"
      end

      after { Time.zone = @zone }

      let(:time) { Time.parse("2014-10-01 09:00") }

      def hour(t)
        t.hour.to_s.rjust(2)
      end

      it "processes a single time into a localized format" do
        mid_time = time + 32.minutes
        presenter = TimePresenter.new(mid_time)
        expect(presenter.as_string).to match(/\d+:\d{2}[ap]m$/)
      end

      it "does not have leading or trailing spaces" do
        presenter = TimePresenter.new(time)
        result = presenter.as_string
        expect(result).to eq result.strip
      end

      it "trims the minutes for an on-the-hour time" do
        presenter = TimePresenter.new(time)
        expect(presenter.as_string).to match(/\d+[ap]m$/)
      end

      it "can present a range of times" do
        time2 = Time.parse("2014-10-01 10:00")
        presenter = TimePresenter.new(time)
        expect(presenter.as_string(display_as_range: time2)).to match(/[ap]m to.*[ap]m$/)
      end

      it "returns nil for nil" do
        presenter = TimePresenter.new(nil)
        expect(presenter.as_string).to be_nil
      end

      it "can accept a zone override" do
        native_zone_presenter = TimePresenter.new(time)
        zone = ActiveSupport::TimeZone["America/Juneau"]
        presenter = TimePresenter.new(time, zone)
        expect(presenter.as_string).to_not eq(native_zone_presenter.as_string)
      end

      it "can handle a nil zone override" do
        native_zone_presenter = TimePresenter.new(time, nil)
        explicit_presenter = TimePresenter.new(time, Time.zone)
        expect(explicit_presenter.as_string).to eq(native_zone_presenter.as_string)
      end
    end
  end
end
