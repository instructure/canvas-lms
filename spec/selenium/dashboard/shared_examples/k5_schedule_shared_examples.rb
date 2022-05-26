# frozen_string_literal: true

#
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

require_relative "../../common"
require_relative "../pages/k5_dashboard_page"
require_relative "../pages/k5_dashboard_common_page"
require_relative "../pages/k5_schedule_tab_page"
require_relative "../../../helpers/k5_common"
require_relative "../../helpers/shared_examples_common"

shared_examples_for "k5 schedule" do
  include K5DashboardPageObject
  include K5DashboardCommonPageObject
  include K5ScheduleTabPageObject
  include K5Common
  include SharedExamplesCommon

  before do
    @now = Time.zone.now
  end

  context "entry" do
    it "navigates to planner when Schedule is clicked" do
      assignment_title = "Today Assignment"
      create_dated_assignment(@subject_course, assignment_title, @now)

      get "/"

      select_schedule_tab
      wait_for_ajaximations

      expect(schedule_item.text).to include(assignment_title)
    end

    it "shows missing assignments on dashboard schedule tab" do
      now = Time.zone.now
      create_dated_assignment(@subject_course, "missing assignment1", 1.day.ago(now))
      create_dated_assignment(@subject_course, "missing assignment2", 1.day.ago(now))

      get "/#schedule"

      expect(missing_data.text).to eq("Show 2 missing items")
    end
  end

  context "navigation" do
    it "starts the current week on the schedule and navigates backwards and forwards" do
      [
        ["Today assignment", @now],
        ["Previous Assignment", 7.days.ago(@now)],
        ["Future Assignment", 7.days.from_now(@now)]
      ].each do |assignment_info|
        create_dated_assignment(@subject_course, assignment_info[0], assignment_info[1])
      end

      get "/#schedule"
      wait_for_ajaximations

      expect(beginning_of_week_date).to include(beginning_weekday_calculation(@now))
      expect(end_of_week_date).to include(ending_weekday_calculation(@now))

      click_previous_week_button
      wait_for_ajaximations

      expect(beginning_of_week_date).to include(beginning_weekday_calculation(1.week.ago(@now)))
      expect(end_of_week_date).to include(ending_weekday_calculation(1.week.ago(@now)))

      click_today_button
      wait_for_ajaximations

      expect(beginning_of_week_date).to include(beginning_weekday_calculation(@now))
      expect(end_of_week_date).to include(ending_weekday_calculation(@now))

      click_next_week_button
      wait_for_ajaximations

      expect(beginning_of_week_date).to include(beginning_weekday_calculation(1.week.from_now(@now)))
      expect(end_of_week_date).to include(ending_weekday_calculation(1.week.from_now(@now)))
    end
  end

  context "subject-scoped schedule tab included items" do
    it "shows schedule info for subject items" do
      create_dated_assignment(@subject_course, "today assignment1", @now)

      get "/courses/#{@subject_course.id}#schedule"

      expect(today_header).to be_displayed
      expect(schedule_item.text).to include("today assignment1")
    end

    it "shows subject missing item in dropdown" do
      create_dated_assignment(@subject_course, "yesterday assignment1", 1.day.ago(@now))

      get "/courses/#{@subject_course.id}#schedule"

      expect(items_missing.text).to eq("Show 1 missing item")
    end
  end

  context "subject-scoped schedule tab excluded items" do
    before(:once) do
      course_with_student(
        active_all: true,
        user: @student,
        course_name: "Social Studies"
      )
      create_dated_assignment(@course, "assignment for other course", @now)
    end

    it "does not show schedule info for non subject item" do
      get "/courses/#{@subject_course.id}#schedule"

      expect(schedule_item_exists?).to be_falsey
    end

    it "does not show non-subject missing item in dropdown" do
      get "/courses/#{@subject_course.id}#schedule"

      expect(items_missing_exists?).to be_falsey
    end
  end

  context "subject color" do
    it "shows the subject color on the planner assignment listing" do
      new_color = "#07AB99"
      @subject_course.update!(course_color: new_color)
      create_dated_assignment(@subject_course, "assignment for other course", @now)

      get "/#schedule"

      expect(hex_value_for_color(planner_assignment_header, "background-color")).to eq(new_color)
    end
  end
end
