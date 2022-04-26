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

  context "course pacing blackout dates modal" do
    it "renders the blackout dates modal when link clicked" do
      visit_course_paces_page
      click_settings_button
      click_manage_blackout_dates

      expect(blackout_dates_modal).to be_displayed
    end

    it "adds blackout date with range of dates" do
      visit_course_paces_page
      click_settings_button
      click_manage_blackout_dates

      blackout_date_title_input.send_keys("Easter Break")
      blackout_date_start_date_input.send_keys("2022-04-15")
      blackout_date_end_date_input.send_keys("2022-04-18")
      click_blackout_dates_add_button

      table_text = blackout_dates_table_items[1].text
      expect(table_text).to include("Easter Break")
      expect(table_text).to include("Fri, Apr 15, 2022")
      expect(table_text).to include("Mon, Apr 18, 2022")
    end

    it "adds blackout date with one date" do
      visit_course_paces_page
      click_settings_button
      click_manage_blackout_dates

      blackout_date_title_input.send_keys("Easter Break")
      blackout_date_start_date_input.send_keys("2022-04-15")
      click_blackout_dates_add_button
      table_text = blackout_dates_table_items[1].text

      expect(table_text).to include("Easter Break")
      expect(table_text).to include("Fri, Apr 15, 2022 Fri, Apr 15, 2022")
    end

    it "deletes a just-added blackout date" do
      visit_course_paces_page
      click_settings_button
      click_manage_blackout_dates

      blackout_date_title_input.send_keys("Easter Break")
      blackout_date_start_date_input.send_keys("2022-04-15")
      click_blackout_dates_add_button

      blackout_date_delete(blackout_dates_table_items[1]).click
      expect(blackout_dates_table_items[1].text).to eq("No blackout dates")
    end

    it "save a just-added blackout date" do
      create_published_course_pace("Pace Module", "Assignment 1")
      visit_course_paces_page
      click_settings_button
      click_manage_blackout_dates

      blackout_date_title_input.send_keys("Easter Break")
      blackout_date_start_date_input.send_keys("2022-04-15")
      click_blackout_dates_add_button

      click_blackout_dates_save_button

      expect(blackout_dates_modal_exists?).to be_falsey

      expect(publish_status_button.text).to eq("1 unpublished change")
      click_unpublished_changes_button

      expect(unpublished_changes_list[0].text).to include("Easter Break")
    end
  end
end
