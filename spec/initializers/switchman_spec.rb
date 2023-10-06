# frozen_string_literal: true

# Copyright (C) 2013 - present Instructure, Inc.
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

require_relative "../spec_helper"

describe Switchman::Shard do
  describe "#activate!" do
    shared_examples_for "#activate!" do
      it "disallows use" do
        expect { Shard.default.activate! }.to raise_error(NotImplementedError)
      end
    end

    context "with sharding" do
      specs_require_sharding

      include_examples "#activate!"
    end

    include_examples "#activate!"
  end

  describe "maintenance_windows" do
    before do
      allow(Setting).to receive(:get).and_call_original
    end

    it "Returns an empty window if no start is defined" do
      allow(Setting).to receive(:get).with("maintenance_window_start_hour", anything).and_return(nil)

      expect(DatabaseServer.all.first.next_maintenance_window).to be_nil # rubocop:disable Rails/RedundantActiveRecordAllMethod
    end

    it "Returns a window of the correct duration" do
      allow(Setting).to receive(:get).with("maintenance_window_start_hour", anything).and_return("0")
      allow(Setting).to receive(:get).with("maintenance_window_duration", anything).and_return("PT3H")

      window = DatabaseServer.all.first.next_maintenance_window # rubocop:disable Rails/RedundantActiveRecordAllMethod

      expect(window[1] - window[0]).to eq(3.hours)
    end

    it "Returns a window starting at the correct time" do
      allow(Setting).to receive(:get).with("maintenance_window_start_hour", anything).and_return("3")

      window = DatabaseServer.all.first.next_maintenance_window # rubocop:disable Rails/RedundantActiveRecordAllMethod

      expect(window[0].utc.hour).to eq(21)

      allow(Setting).to receive(:get).with("maintenance_window_start_hour", anything).and_return("-7")

      window = DatabaseServer.all.first.next_maintenance_window # rubocop:disable Rails/RedundantActiveRecordAllMethod

      expect(window[0].utc.hour).to eq(7)
    end

    it "Returns a window on the correct day" do
      allow(Setting).to receive(:get).with("maintenance_window_start_hour", anything).and_return("0")
      allow(Setting).to receive(:get).with("maintenance_window_weekday", anything).and_return("Tuesday")

      window = DatabaseServer.all.first.next_maintenance_window # rubocop:disable Rails/RedundantActiveRecordAllMethod

      expect(window[0].wday).to eq(Date::DAYNAMES.index("Tuesday"))
    end

    context "with a positive timezone" do
      before do
        @old_zone = Time.zone
        Time.zone = ActiveSupport::TimeZone["Melbourne"]
      end

      after do
        Time.zone = @old_zone
      end

      it "Returns a window on the correct day" do
        allow(Setting).to receive(:get).with("maintenance_window_start_hour", anything).and_return("0")
        allow(Setting).to receive(:get).with("maintenance_window_weekday", anything).and_return("Tuesday")

        window = DatabaseServer.all.first.next_maintenance_window # rubocop:disable Rails/RedundantActiveRecordAllMethod

        expect(window[0].wday).to eq(Date::DAYNAMES.index("Tuesday"))
      end
    end

    it "Returns a window on the correct day of the month" do
      allow(Setting).to receive(:get).with("maintenance_window_start_hour", anything).and_return("0")
      allow(Setting).to receive(:get).with("maintenance_window_weekday", anything).and_return("Tuesday")
      allow(Setting).to receive(:get).with("maintenance_window_weeks_of_month", anything).and_return("2,4")

      Timecop.freeze(Time.utc(2021, 3, 1, 12, 0)) do
        window = DatabaseServer.all.first.next_maintenance_window # rubocop:disable Rails/RedundantActiveRecordAllMethod

        # The 9th was the second tuesday of that month
        expect(window[0].day).to eq(9)
      end

      Timecop.freeze(Time.utc(2021, 3, 10, 12, 0)) do
        window = DatabaseServer.all.first.next_maintenance_window # rubocop:disable Rails/RedundantActiveRecordAllMethod

        # The 23rd was the fourth tuesday of that month
        expect(window[0].day).to eq(23)
      end
    end
  end
end
