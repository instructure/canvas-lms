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

require_relative "pages/coursepaces_common_page"
require_relative "pages/coursepaces_landing_page"
require_relative "../courses/pages/courses_home_page"
require_relative "pages/coursepaces_page"

describe "course pace search and sort" do
  include_context "in-process server selenium tests"
  include CoursePacesCommonPageObject
  include CoursePacesLandingPageObject
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
    Account.site_admin.enable_feature!(:course_paces_redesign)
    Account.site_admin.enable_feature!(:course_paces_for_students)
  end

  before do
    user_session @teacher
  end

  context "search sections and students in course pace table" do
    before :once do
      15.times do |x|
        @course.course_sections.create!(name: "Sections to Search #{x}")
      end
      n_students_in_course(15, course: @course)
      create_published_course_pace("Course Pace 1", "Module Assignment 1")
    end

    it "searches for a section by name" do
      visit_course_paces_page

      expect(course_pace_table_rows.count).to eq(10)

      search_input.send_keys("Sections to Search 1")
      click_search_button

      expect(course_pace_table_rows.count).to eq(6)
    end

    it "searches for existing students in student list" do
      visit_course_paces_page
      click_student_tab
      expect(course_pace_table_rows.count).to eq(10)

      search_input.send_keys("user 1")
      click_search_button

      expect(course_pace_table_rows.count).to eq(7)
    end

    it "searches for section that does not exist" do
      visit_course_paces_page

      search_input.send_keys("Sections to search 90")
      click_search_button

      expect(element_exists?(course_pace_table_rows_selector)).to be_falsey
      # Should look for empty state when that ticket is done (LS-3612)
    end

    it "attempts to search then clears search" do
      visit_course_paces_page

      search_input.send_keys("Sections to search 1")
      click_search_button
      expect(course_pace_table_rows.count).to eq(6)

      search_input.send_keys([:control, "a"], :backspace)

      click_search_button

      expect(course_pace_table_rows.count).to eq(10)
    end
  end

  context "table sorting" do
    before :once do
      %w[a b c d e].each do |x|
        @course.course_sections.create!(name: "#{x} section to search")
      end
      n_students_in_course(5, course: @course)
      create_published_course_pace("Course Pace 1", "Module Assignment 1")
    end

    it "starts section table as sorted ascending by section name" do
      visit_course_paces_page

      expect(course_pace_table_rows.first.text).to include("a section to search")
      expect(course_pace_table_rows.last.text).to include("e section to search")
    end

    it "sorts section table descending by section name when column heading clicked" do
      visit_course_paces_page

      click_table_column_name

      expect(course_pace_table_rows.first.text).to include("e section to search")
      expect(course_pace_table_rows.last.text).to include("a section to search")

      click_table_column_name

      expect(course_pace_table_rows.first.text).to include("a section to search")
      expect(course_pace_table_rows.last.text).to include("e section to search")
    end

    it "starts student table as sorted ascending by student name" do
      visit_course_paces_page
      click_student_tab

      expect(course_pace_table_rows.first.text).to include("Jessi Jenkins")
      expect(course_pace_table_rows.last.text).to include("user 5")
    end

    it "sorts student table descending by student name when column heading clicked" do
      visit_course_paces_page
      click_student_tab
      click_table_column_name

      expect(course_pace_table_rows.first.text).to include("user 5")
      expect(course_pace_table_rows.last.text).to include("Jessi Jenkins")

      click_table_column_name
      expect(course_pace_table_rows.first.text).to include("Jessi Jenkins")
      expect(course_pace_table_rows.last.text).to include("user 5")
    end
  end
end
