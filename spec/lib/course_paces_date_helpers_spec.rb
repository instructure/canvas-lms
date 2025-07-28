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
  before do
    course_with_student active_all: true
    @course.update start_at: "2022-09-01", restrict_enrollments_to_course_dates: true
    @course_pace = @course.course_paces.create!(
      workflow_state: "active"
    )
  end

  describe "add_days" do
    context "when add_selected_days_to_skip_param is enabled" do
      before do
        @course.root_account.enable_feature!(:course_paces_skip_selected_days)
        @course_pace.update selected_days_to_skip: %w[sat sun]
      end

      it "adds days" do
        start_date = Date.new(2022, 5, 9) # monday
        expect(
          CoursePacesDateHelpers.add_days(start_date, 3, @course_pace, [])
        ).to eq Date.new(2022, 5, 12)
      end

      it "skips weekends" do
        start_date = Date.new(2022, 5, 9) # monday
        expect(
          CoursePacesDateHelpers.add_days(start_date, 5, @course_pace, [])
        ).to eq Date.new(2022, 5, 16)
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
        expect(
          CoursePacesDateHelpers.add_days(start_date, 2, @course_pace, blackout_dates)
        ).to eq Date.new(2022, 5, 13)
      end
    end

    context "when add_selected_days_to_skip_param is disabled" do
      before do
        @course.root_account.disable_feature!(:course_paces_skip_selected_days)
        @course_pace.update exclude_weekends: true
      end

      it "adds days" do
        start_date = Date.new(2022, 5, 9) # monday
        expect(
          CoursePacesDateHelpers.add_days(start_date, 3, @course_pace, [])
        ).to eq Date.new(2022, 5, 12)
      end

      it "skips weekends" do
        start_date = Date.new(2022, 5, 9) # monday
        expect(
          CoursePacesDateHelpers.add_days(start_date, 5, @course_pace, [])
        ).to eq Date.new(2022, 5, 16)
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
        expect(
          CoursePacesDateHelpers.add_days(start_date, 2, @course_pace, blackout_dates)
        ).to eq Date.new(2022, 5, 13)
      end
    end
  end

  describe "previous_enabled_day" do
    context "when add_selected_days_to_skip_param is enabled" do
      before do
        @course.root_account.enable_feature!(:course_paces_skip_selected_days)
        @course_pace.update selected_days_to_skip: %w[sat sun]
      end

      it "avoids weekends" do
        end_date = Date.new(2022, 5, 8) # sunday
        expect(
          CoursePacesDateHelpers.previous_enabled_day(end_date, @course_pace, [])
        ).to eq Date.new(2022, 5, 6)
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
        expect(
          CoursePacesDateHelpers.previous_enabled_day(end_date, @course_pace, blackout_dates)
        ).to eq Date.new(2022, 5, 4)
      end
    end

    context "when add_selected_days_to_skip_param is disabled" do
      before do
        @course.root_account.disable_feature!(:course_paces_skip_selected_days)
        @course_pace.update exclude_weekends: true
      end

      it "avoids weekends" do
        end_date = Date.new(2022, 5, 8) # sunday
        expect(
          CoursePacesDateHelpers.previous_enabled_day(end_date, @course_pace, [])
        ).to eq Date.new(2022, 5, 6)
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
        expect(
          CoursePacesDateHelpers.previous_enabled_day(end_date, @course_pace, blackout_dates)
        ).to eq Date.new(2022, 5, 4)
      end
    end
  end

  describe "first_enabled_day" do
    context "when add_selected_days_to_skip_param is enabled" do
      before do
        @course.root_account.enable_feature!(:course_paces_skip_selected_days)
        @course_pace.update selected_days_to_skip: %w[sat sun]
      end

      it "avoids weekends" do
        start_date = Date.new(2022, 5, 7) # saturday
        expect(
          CoursePacesDateHelpers.first_enabled_day(start_date, @course_pace, [])
        ).to eq Date.new(2022, 5, 9)
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
        expect(
          CoursePacesDateHelpers.first_enabled_day(end_date, @course_pace, blackout_dates)
        ).to eq Date.new(2022, 5, 11)
      end
    end

    context "when add_selected_days_to_skip_param is disabled" do
      before do
        @course.root_account.disable_feature!(:course_paces_skip_selected_days)
        @course_pace.update exclude_weekends: true
      end

      it "avoids weekends" do
        start_date = Date.new(2022, 5, 7) # saturday
        expect(
          CoursePacesDateHelpers.first_enabled_day(start_date, @course_pace, [])
        ).to eq Date.new(2022, 5, 9)
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
        expect(
          CoursePacesDateHelpers.first_enabled_day(end_date, @course_pace, blackout_dates)
        ).to eq Date.new(2022, 5, 11)
      end
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

    context "when add_selected_days_to_skip_param is enabled" do
      before do
        @course.root_account.enable_feature!(:course_paces_skip_selected_days)
        @course_pace.update selected_days_to_skip: %w[sat sun]
      end

      it "enables weekdays" do
        date = Date.new(2022, 5, 9) # monday
        expect(
          CoursePacesDateHelpers.day_is_enabled?(date, @course_pace, @blackout_dates)
        ).to be_truthy
      end

      it "disables weekends" do
        date = Date.new(2022, 5, 8) # sunday
        expect(
          CoursePacesDateHelpers.day_is_enabled?(date, @course_pace, @blackout_dates)
        ).to be_falsey
      end

      it "disables blackout dates" do
        date = Date.new(2022, 5, 10)
        expect(
          CoursePacesDateHelpers.day_is_enabled?(date, @course_pace, @blackout_dates)
        ).to be_falsey
      end
    end

    context "when add_selected_days_to_skip_param is disabled" do
      before do
        @course.root_account.disable_feature!(:course_paces_skip_selected_days)
        @course_pace.update exclude_weekends: true
      end

      it "enables weekdays" do
        date = Date.new(2022, 5, 9) # monday
        expect(
          CoursePacesDateHelpers.day_is_enabled?(date, @course_pace, @blackout_dates)
        ).to be_truthy
      end

      it "disables weekends" do
        date = Date.new(2022, 5, 8) # sunday
        expect(
          CoursePacesDateHelpers.day_is_enabled?(date, @course_pace, @blackout_dates)
        ).to be_falsey
      end

      it "disables blackout dates" do
        date = Date.new(2022, 5, 10)
        expect(
          CoursePacesDateHelpers.day_is_enabled?(date, @course_pace, @blackout_dates)
        ).to be_falsey
      end
    end
  end

  describe "days_between" do
    context "when add_selected_days_to_skip_param is enabled" do
      before do
        @course.root_account.enable_feature!(:course_paces_skip_selected_days)
        @course_pace.update selected_days_to_skip: %w[sat sun]
      end

      it "counts work days weekends included" do
        start_date = Date.new(2022, 5, 9) # monday
        end_date = Date.new(2022, 5, 16) # monday
        @course_pace.update selected_days_to_skip: []
        @course_pace.reload
        expect(CoursePacesDateHelpers.days_between(start_date, end_date, @course_pace)).to eq 8
      end

      it "skips weekends" do
        start_date = Date.new(2022, 5, 9) # monday
        end_date = Date.new(2022, 5, 16) # monday
        expect(CoursePacesDateHelpers.days_between(start_date, end_date, @course_pace)).to eq 6
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
        expect(
          CoursePacesDateHelpers.days_between(
            start_date,
            end_date,
            @course_pace,
            inclusive_end: true,
            blackout_dates:
          )
        ).to eq 4
      end
    end

    context "when add_selected_days_to_skip_param is disabled" do
      before do
        @course.root_account.disable_feature!(:course_paces_skip_selected_days)
        @course_pace.update exclude_weekends: true
      end

      it "counts work days exclude weekends false" do
        start_date = Date.new(2022, 5, 9) # monday
        end_date = Date.new(2022, 5, 16) # monday
        @course_pace.update exclude_weekends: false
        @course_pace.reload
        expect(CoursePacesDateHelpers.days_between(start_date, end_date, @course_pace)).to eq 8
      end

      it "skips weekends" do
        start_date = Date.new(2022, 5, 9) # monday
        end_date = Date.new(2022, 5, 16) # monday
        expect(CoursePacesDateHelpers.days_between(start_date, end_date, @course_pace)).to eq 6
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
        expect(
          CoursePacesDateHelpers.days_between(
            start_date,
            end_date,
            @course_pace,
            inclusive_end: true,
            blackout_dates:
          )
        ).to eq 4
      end
    end
  end
end
