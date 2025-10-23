# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require_relative "page_objects/course_tab_page"

describe "student dashboard people widget", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include CourseTabPage

  before :once do
    course_tab_setup
  end

  before do
    user_session(@student)
  end

  context "course tab smoke tests" do
    it "displays course cards" do
      go_to_course_tab

      expect(all_course_cards.size).to eq(3)

      expect(all_action_links(@course1.name).size).to eq(3)
      expect(all_action_links(@course2.name).size).to eq(4)
      expect(all_action_links(@course3.name).size).to eq(2)
    end

    it "navigates to the correct course when clicking on a course card" do
      go_to_course_tab

      expect(course_card_title_link(@course1.name)).to be_displayed
      course_card_title_link(@course1.name).click
      expect(driver.current_url).to include("/courses/#{@course1.id}")
    end

    it "navigates to the files page when clicking on the files action link" do
      go_to_course_tab

      expect(course_card_action(@course3.name, "Files")).to be_displayed
      course_card_action(@course3.name, "Files").click
      expect(driver.current_url).to include("/courses/#{@course3.id}/files")
    end

    it "navigates to the announcements page when clicking on the announcements action link" do
      go_to_course_tab

      expect(course_card_action(@course1.name, "Announcements")).to be_displayed
      expect(course_card_action_badge(@course1.name, "Announcements").text).to eq("4\nUnread")
      course_card_action(@course1.name, "Announcements").click
      expect(driver.current_url).to include("/courses/#{@course1.id}/announcements")
    end

    it "navigates to the assignments page when clicking on the assignments action link" do
      go_to_course_tab

      expect(course_card_action(@course2.name, "Assignments")).to be_displayed
      course_card_action(@course2.name, "Assignments").click
      expect(driver.current_url).to include("/courses/#{@course2.id}/assignments")
    end

    it "navigates to the discussions page when clicking on the discussions action link" do
      go_to_course_tab

      expect(course_card_action(@course2.name, "Discussions")).to be_displayed
      expect(course_card_action_badge(@course2.name, "Discussions").text).to eq("1\nUnread")
      course_card_action(@course2.name, "Discussions").click
      expect(driver.current_url).to include("/courses/#{@course2.id}/discussion_topics")
    end
  end
end
