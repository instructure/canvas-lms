# frozen_string_literal: true

# Copyright (C) 2022 - present Instructure, Inc.
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

describe CoursePacesDateHelpers do
  describe "add_days" do
    it "adds days" do
      start_date = Date.new(2022, 5, 9) # monday
      expect(CoursePacesDateHelpers.add_days(start_date, 3, false, [])).to eq Date.new(2022, 5, 12)
    end

    it "skips weekends" do
      start_date = Date.new(2022, 5, 9) # monday
      expect(CoursePacesDateHelpers.add_days(start_date, 5, true, [])).to eq Date.new(2022, 5, 16)
    end

    it "skips blackout dates" do
      start_date = Date.new(2022, 5, 9) # monday
      blackout_dates = [
        BlackoutDate.new(
          event_title: "blackout dates 1",
          start_date: Date.new(2022, 5, 10),
          end_date: Date.new(2022, 5, 11)
        )
      ]
      expect(CoursePacesDateHelpers.add_days(start_date, 2, true, blackout_dates)).to eq Date.new(2022, 5, 13)
    end
  end

  describe "previous_enabled_day" do
    it "avoids weekends" do
      end_date = Date.new(2022, 5, 8) # sunday
      expect(CoursePacesDateHelpers.previous_enabled_day(end_date, true, [])).to eq Date.new(2022, 5, 6)
    end

    it "avoids blackout dates" do
      end_date = Date.new(2022, 5, 6) # friday
      blackout_dates = [
        BlackoutDate.new(
          event_title: "blackout dates 1",
          start_date: Date.new(2022, 5, 5),
          end_date: Date.new(2022, 5, 6)
        )
      ]
      expect(CoursePacesDateHelpers.previous_enabled_day(end_date, true, blackout_dates)).to eq Date.new(2022, 5, 4)
    end
  end

  describe "first_enabled_day" do
    it "avoids weekends" do
      start_date = Date.new(2022, 5, 7) # saturday
      expect(CoursePacesDateHelpers.first_enabled_day(start_date, true, [])).to eq Date.new(2022, 5, 9)
    end

    it "avoids blackout dates" do
      end_date = Date.new(2022, 5, 9) # monday
      blackout_dates = [
        BlackoutDate.new(
          event_title: "blackout dates 1",
          start_date: Date.new(2022, 5, 9),
          end_date: Date.new(2022, 5, 10)
        )
      ]
      expect(CoursePacesDateHelpers.first_enabled_day(end_date, true, blackout_dates)).to eq Date.new(2022, 5, 11)
    end
  end

  describe "day_is_enabled?" do
    before :once do
      @blackout_dates = [
        BlackoutDate.new(
          event_title: "blackout dates 1",
          start_date: Date.new(2022, 5, 10),
          end_date: Date.new(2022, 5, 11)
        )
      ]
    end

    it "enables weekdays" do
      date = Date.new(2022, 5, 9) # monday
      expect(CoursePacesDateHelpers.day_is_enabled?(date, true, @blackout_dates)).to be_truthy
    end

    it "disables weekends" do
      date = Date.new(2022, 5, 8) # sunday
      expect(CoursePacesDateHelpers.day_is_enabled?(date, true, @blackout_dates)).to be_falsey
    end

    it "disables blackout dates" do
      date = Date.new(2022, 5, 10)
      expect(CoursePacesDateHelpers.day_is_enabled?(date, true, @blackout_dates)).to be_falsey
    end
  end

  describe "days_between" do
    it "counts work days" do
      start_date = Date.new(2022, 5, 9) # monday
      end_date = Date.new(2022, 5, 16) # monday
      expect(CoursePacesDateHelpers.days_between(start_date, end_date, false)).to eq 8
    end

    it "skips weekends" do
      start_date = Date.new(2022, 5, 9) # monday
      end_date = Date.new(2022, 5, 16) # monday
      expect(CoursePacesDateHelpers.days_between(start_date, end_date, true)).to eq 6
    end

    it "skips blackout dates" do
      start_date = Date.new(2022, 5, 9) # monday
      end_date = Date.new(2022, 5, 16) # monday
      blackout_dates = [
        BlackoutDate.new(
          event_title: "blackout dates 1",
          start_date: Date.new(2022, 5, 10),
          end_date: Date.new(2022, 5, 11)
        )
      ]
      expect(CoursePacesDateHelpers.days_between(start_date, end_date, true, inclusive_end: true, blackout_dates:)).to eq 4
    end
  end
end
