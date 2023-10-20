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

describe "admin k5 dashboard" do
  include_context "in-process server selenium tests"
  include K5DashboardPageObject
  include K5DashboardCommonPageObject
  include K5ScheduleTabPageObject
  include K5Common

  before :once do
    admin_setup
  end

  before do
    user_session @admin
  end

  context "homeroom dashboard standard" do
    it "provides the homeroom dashboard tabs on dashboard" do
      get "/"
      expect(welcome_title).to be_present
      expect(homeroom_tab).to be_displayed
      expect(schedule_tab).to be_displayed
      expect(grades_tab).to be_displayed
      expect(resources_tab).to be_displayed
    end

    it "allows admins to switch back to the classic dashboard" do
      get "/"

      expect(dashboard_options_button).to be_displayed

      options = dashboard_options
      expect(options.length).to be 2
      expect(options[0].text).to eq("Classic View")
      expect(options[1].text).to eq("Homeroom View")

      options[0].click
      wait_for_ajaximations

      expect(classic_dashboard_header).to be_displayed
    end
  end

  context "new course creation" do
    it "provides a new course button for admin" do
      get "/"

      expect(new_course_button).to be_displayed
    end

    it "provides a new course modal when new course button clicked" do
      get "/"

      click_new_course_button

      expect(new_course_modal).to be_displayed
    end

    it "closes the course modal when x is clicked" do
      get "/"

      click_new_course_button

      expect(new_course_modal_close_button).to be_displayed

      click_new_course_close_button

      expect(new_course_modal_exists?).to be_falsey
    end

    it "closes the course modal when cancel is clicked" do
      get "/"

      click_new_course_button

      expect(new_course_modal_close_button).to be_displayed

      course_name = "Awesome Course"
      fill_out_course_modal(@account, course_name)

      click_new_course_cancel

      expect(new_course_modal_exists?).to be_falsey
      latest_course = Course.last
      expect(latest_course.name).not_to eq(course_name)
    end

    it "creates course with account name and course name", :ignore_js_errors, custom_timeout: 30 do
      get "/"

      click_new_course_button
      expect(new_course_modal_exists?).to be_truthy

      course_name = "Awesome Course"

      fill_out_course_modal(@account, course_name)
      click_new_course_create
      wait_for_ajaximations

      expect(new_course_modal_exists?).to be_falsey

      latest_course = Course.last
      expect(latest_course.name).to eq(course_name)
      expect(driver.current_url).to include("/courses/#{latest_course.id}/settings")
    end

    it "allows for sync of course to selected homeroom", :ignore_js_errors, custom_timeout: 30 do
      second_homeroom_course_name = "Second homeroom course"

      course_with_teacher(
        account: @account,
        active_course: 1,
        active_enrollment: 1,
        course_name: second_homeroom_course_name,
        user: @homeroom_teacher
      )
      Course.last.update!(homeroom_course: true)

      get "/"
      click_new_course_button

      new_course_name = "Amazing Course One"
      fill_out_course_modal(@account, new_course_name)
      click_sync_enrollments_checkbox
      click_option(homeroom_select_selector, second_homeroom_course_name)
      click_new_course_create

      expect(new_course_modal_exists?).to be_falsey
      expect(course_homeroom_option(second_homeroom_course_name)).to have_attribute("selected", "true")
    end
  end

  context "admin schedule" do
    it "shows an empty state for the admin (teacher) view of the course schedule tab with no enrollments" do
      get "/#schedule"

      expect(empty_dashboard).to be_displayed
    end

    it "shows a sample preview for admin (teacher) view of the course schedule tab" do
      get "/courses/#{@subject_course.id}#schedule"

      expect(teacher_preview).to be_displayed
    end
  end
end
