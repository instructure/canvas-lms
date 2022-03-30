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

require_relative "../common"
require_relative "pages/coursepaces_common_page"
require_relative "pages/coursepaces_page"
require_relative "../courses/pages/courses_home_page"

describe "course pace page" do
  include_context "in-process server selenium tests"
  include CoursePacesCommonPageObject
  include CoursePacesPageObject
  include CoursesHomePage

  before :once do
    teacher_setup
    course_with_student(
      active_all: true,
      name: "Jessi Jenkins",
      course: @course
    )
    enable_course_paces_in_course
  end

  before do
    user_session @teacher
  end

  context "course paces show/hide projections" do
    it "have a projections button that changes text from hide to show when pressed" do
      visit_course_paces_page

      expect(show_hide_course_paces_button_text).to eq("Show Projections")

      click_show_hide_projections_button

      expect(show_hide_course_paces_button_text).to eq("Hide Projections")
    end

    it "shows start and end date fields when Show Projections button is clicked" do
      visit_course_paces_page

      click_show_hide_projections_button

      expect(course_pace_start_date).to be_displayed
      expect(course_pace_end_date).to be_displayed
    end

    it "does not show date fields when Hide Projections button is clicked" do
      visit_course_paces_page

      click_show_hide_projections_button
      click_show_hide_projections_button

      expect(course_pace_start_date_exists?).to be_falsey
      expect(course_pace_end_date_exists?).to be_falsey
    end

    it "shows only a projection icon when window size is narrowed" do
      visit_course_paces_page

      window_size_width = driver.manage.window.size.width
      window_size_height = driver.manage.window.size.height
      driver.manage.window.resize_to((window_size_width / 2).to_i, window_size_height)
      scroll_to_element(show_hide_button_with_icon)

      expect(show_hide_icon_button_exists?).to be_truthy
      expect(show_hide_course_paces_exists?).to be_falsey
    end

    it "shows an error message when weekend date is input and skip weekends is toggled on" do
      visit_course_paces_page
      click_show_hide_projections_button
      add_start_date(calculate_saturday_date)

      expect { course_paces_page_text.include?("The selected date is on a weekend and this course pace skips weekends.") }.to become(true)
    end

    it "shows a due date tooltip when plan is compressed" do
      @course_module = create_course_module("New Module", "active")
      @assignment = create_assignment(@course, "Module Assignment", "Module Assignment Description", 10, "published")
      @module_item = @course_module.add_item(id: @assignment.id, type: "assignment")

      visit_course_paces_page
      click_show_hide_projections_button
      click_require_end_date_checkbox

      today = Date.today
      add_start_date(today)
      add_required_end_date(today + 10.days)
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

      visit_course_paces_page
      click_show_hide_projections_button

      expect(number_of_assignments.text).to eq("2 assignments")
      expect(number_of_weeks.text).to eq("0 weeks")

      update_module_item_duration(0, 6)

      expect(number_of_weeks.text).to eq("1 week")
    end

    it "shows Dates shown in course time zone text" do
      @course_module = create_course_module("New Module", "active")
      @assignment = create_assignment(@course, "Module Assignment", "Module Assignment Description", 10, "published")
      @module_item = @course_module.add_item(id: @assignment.id, type: "assignment")

      visit_course_paces_page
      click_show_hide_projections_button

      expect(dates_shown).to be_displayed
    end
  end

  context "Projected Dates" do
    it "toggles provides input field for required end date when clicked" do
      visit_course_paces_page
      click_show_hide_projections_button

      click_require_end_date_checkbox
      expect(is_checked(require_end_date_checkbox_selector)).to be_truthy
      expect(required_end_date_input_exists?).to be_truthy
      expect(required_end_date_message).to be_displayed

      click_require_end_date_checkbox
      expect(is_checked(require_end_date_checkbox_selector)).to be_falsey
      expect(hypothetical_end_date).to be_displayed
    end

    it "allows inputting a date in the required date field" do
      later_date = Time.zone.now + 2.weeks
      visit_course_paces_page
      click_show_hide_projections_button

      click_require_end_date_checkbox
      add_required_end_date(later_date)

      expect(required_end_date_value).to eq(format_date_for_view(later_date, "%B %-d, %Y"))
    end
  end

  context "Skip Weekend Interactions" do
    before :once do
      @course_module = create_course_module("New Module", "active")
      @assignment = create_assignment(@course, "Module Assignment", "Module Assignment Description", 10, "published")
      @module_item = @course_module.add_item(id: @assignment.id, type: "assignment")
    end

    it "shows dates with weekends included in calculation" do
      visit_course_paces_page
      click_settings_button
      click_weekends_checkbox
      click_show_hide_projections_button
      today = Date.today
      add_start_date(today)
      update_module_item_duration(0, 7)

      expect(assignment_due_date_text).to eq(format_date_for_view(today + 7.days, "%a, %b %-d, %Y"))
    end

    it "shows dates with weekends not included in calculation" do
      visit_course_paces_page
      click_settings_button
      click_show_hide_projections_button
      today = Date.today
      add_start_date(today)
      update_module_item_duration(0, 7)

      expect(assignment_due_date_text).to eq(format_date_for_view(skip_weekends(today, 7), "%a, %b %-d, %Y"))
    end
  end
end
