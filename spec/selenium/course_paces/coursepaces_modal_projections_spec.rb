# frozen_string_literal: true

#
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

require_relative "../common"
require_relative "pages/coursepaces_common_page"
require_relative "pages/coursepaces_page"
require_relative "../courses/pages/courses_home_page"
require_relative "pages/coursepaces_landing_page"

describe "course pacing page" do
  include_context "in-process server selenium tests"
  include CoursePacesCommonPageObject
  include CoursePacesPageObject
  include CoursesHomePage
  include CoursePacesLandingPageObject

  before do
    teacher_setup
    course_with_student(
      active_all: true,
      name: "Jessi Jenkins",
      course: @course
    )
    enable_course_paces_in_course
    Account.site_admin.enable_feature!(:course_paces_redesign)
    Account.site_admin.enable_feature!(:course_paces_for_students)
    user_session @teacher
  end

  context "course pacing dates visibility" do
    it "shows start and end dates" do
      @course.start_at = Date.today
      @course.conclude_at = Date.today + 1.month
      @course.restrict_enrollments_to_course_dates = true
      @course.save!
      visit_course_paces_page
      click_create_default_pace_button

      expect(course_pace_start_date).to be_displayed
      expect(course_pace_end_date).to be_displayed
    end

    it "shows a due date tooltip when plan is compressed" do
      @course_module = create_course_module("New Module", "active")
      @assignment = create_assignment(@course, "Module Assignment", "Module Assignment Description", 10, "published")
      @module_item = @course_module.add_item(id: @assignment.id, type: "assignment")
      today = Date.today
      @course.start_at = today
      @course.conclude_at = today + 10.days
      @course.restrict_enrollments_to_course_dates = true
      @course.save!

      visit_course_paces_page
      click_create_default_pace_button

      update_module_item_duration(0, "15")
      wait_for(method: nil, timeout: 10) { compression_tooltip.displayed? }
      expect(compression_tooltip).to be_displayed
    end

    it "shows the number of assignments and how many weeks used in plan" do
      @course_module = create_course_module("New Module", "active")
      @assignment = create_assignment(@course, "Module Assignment", "Module Assignment Description", 10, "published")
      @module_item = @course_module.add_item(id: @assignment.id, type: "assignment")
      discussion_assignment = create_graded_discussion(@course, "Module Discussion", "published")
      @course_module.add_item(id: discussion_assignment.id, type: "discussion_topic")
      Timecop.freeze(Time.zone.local(2022, 3, 23, 13, 0, 0)) do # a wednesday
        visit_course_paces_page
        click_create_default_pace_button

        expect(course_pace_assignment_info.text).to eq("Assignments\n2")

        expect(duration_info.text).to include("0 weeks, 1 day")

        update_module_item_duration(0, 6)

        expect(duration_info.text).to include("1 week, 2 days")
      end
    end

    it "shows Dates shown in course time zone text" do
      skip("LS-2616 Redesigned code needs the time zone info")
      @course_module = create_course_module("New Module", "active")
      @assignment = create_assignment(@course, "Module Assignment", "Module Assignment Description", 10, "published")
      @module_item = @course_module.add_item(id: @assignment.id, type: "assignment")

      visit_course_paces_page
      click_create_default_pace_button

      expect(dates_shown).to be_displayed
    end
  end

  context "Skip Weekend Interactions" do
    let(:today) { Date.parse("2022-05-09") }

    before do
      @course_module = create_course_module("New Module", "active")
      @assignment = create_assignment(@course, "Module Assignment", "Module Assignment Description", 10, "published")
      @module_item = @course_module.add_item(id: @assignment.id, type: "assignment")

      @course.start_at = today
      @course.conclude_at = today + 1.month
      @course.restrict_enrollments_to_course_dates = true
      @course.save!
    end

    it "shows dates with weekends included in calculation" do
      visit_course_paces_page
      click_create_default_pace_button
      click_course_pace_settings_button
      click_weekends_checkbox
      update_module_item_duration(0, 7)

      expect(assignment_due_date_text).to eq(format_date_for_view(today + 7.days, "%a, %b %-d, %Y"))
    end

    it "shows dates with weekends not included in calculation" do
      visit_course_paces_page
      click_create_default_pace_button
      update_module_item_duration(0, 7)

      expect(assignment_due_date_text).to eq(format_date_for_view(skip_weekends(today, 7), "%a, %b %-d, %Y"))
    end
  end
end
