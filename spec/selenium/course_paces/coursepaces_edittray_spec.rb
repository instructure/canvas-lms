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

describe "course paces edit tray" do
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

  context "edit tray contents" do
    let(:pace_module_title) { "Pace Module" }
    let(:module_assignment_title) { "Module Assignment 1" }

    before :once do
      create_published_course_pace(pace_module_title, module_assignment_title)
    end

    it "shows tray link not available when updates have not been made" do
      visit_course_paces_page

      expect(publish_status).to be_displayed
      expect(publish_status.text).to eq("All changes published")
      expect(publish_status_button_exists?).to be_falsey
    end

    it "provides tray link button when updates have been made" do
      visit_course_paces_page

      expect(publish_status_button_exists?).to be_falsey

      update_module_item_duration(0, 3)
      expect(publish_status_button_exists?).to be_truthy
      expect(publish_status_button.text).to eq("1 unpublished change")

      update_module_item_duration(0, 2)
      expect(publish_status_button_exists?).to be_falsey
      expect(publish_status).to be_displayed
    end

    it "brings up the edit tray when unpublished changes button is clicked" do
      visit_course_paces_page

      update_module_item_duration(0, 3)
      click_unpublished_changes_button

      expect(unpublished_changes_tray).to be_displayed
    end

    it "shows the unpublished change in the tray" do
      visit_course_paces_page

      update_module_item_duration(0, 3)
      click_unpublished_changes_button

      expect(unpublished_changes_list[0].text).to include(module_assignment_title)
    end

    it "closes the tray when close button clicked" do
      visit_course_paces_page

      update_module_item_duration(0, 3)
      click_unpublished_changes_button
      click_edit_tray_close_button

      expect(unpublished_changes_tray_exists?).to be_falsey
    end
  end
end
