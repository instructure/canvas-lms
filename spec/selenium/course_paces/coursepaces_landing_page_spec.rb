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

describe "course pace landing page" do
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

  context "unpublished course paces landing page elements" do
    it "navigates to the course paces page when clicked" do
      get "/courses/#{@course.id}"

      click_course_paces

      expect(driver.current_url).to include("/courses/#{@course.id}/course_pacing")
      expect(create_default_pace_button.text).to eq("Create Course Pace")
    end

    it "lands on the getting started course pace landing page when visited the first time" do
      visit_course_paces_page

      expect(create_default_pace_button.text).to eq("Create Course Pace")
      expect(get_started_button).to be_displayed
      expect(course_paces_panda).to be_displayed
    end

    it "goes to go course pace creation page with Get Started button", custom_timeout: 30 do
      visit_course_paces_page
      click_get_started_button

      expect(element_exists?(course_pace_modal_x_selector)).to be_truthy
    end

    it "provides a link to the canvas community user group" do
      visit_course_paces_page
      expect(element_value_for_attr(community_info_text, "href")).to include("community.canvaslms.com/t5/Course-Pacing-Feature-Preview/gh-p/course_pacing")
    end
  end

  context "published course paces landing page" do
    before :once do
      create_published_course_pace("Course Pace 1", "Module Assignment 1")
    end

    it "navigates to the course paces page with publish info when clicked", custom_timeout: 25 do
      get "/courses/#{@course.id}"

      click_course_paces

      expect(driver.current_url).to include("/courses/#{@course.id}/course_pacing")
      expect(create_default_pace_button.text).to eq("Edit Default Course Pace")
    end

    it "lands on the editing course pace landing page when visited" do
      visit_course_paces_page

      expect(create_default_pace_button.text).to eq("Edit Default Course Pace")
      expect(element_exists?(get_started_button_selector)).to be_falsey
    end

    it "shows the context table and the student, section, and default course duration date" do
      @course.course_sections.create!(name: "New Section")

      visit_course_paces_page

      expect(course_pace_context_table).to be_displayed
      expect(number_of_students.text).to include("1")
      expect(number_of_sections.text).to include("2")
      expect(default_duration.text).to include("3 days")
    end
  end

  context "course pace table for sections" do
    before :once do
      create_published_course_pace("Course Pace 1", "Module Assignment 1")
      3.times do |x|
        @course.course_sections.create!(name: "New Section #{x}")
      end
    end

    it "includes all sections, including the default section" do
      visit_course_paces_page

      expect(course_pace_table_rows.count).to eq(4)
    end

    it "section includes student_number and pace type" do
      course_section = @course.course_sections.create!(name: "Best Section")
      create_section_pace(course_section)

      student_enrollment = Enrollment.find_by(user_id: @student.id)
      student_enrollment.course_section = course_section
      student_enrollment.save!
      student_enrollment.reload

      visit_course_paces_page

      expect(context_row("Best Section").text).to include("1 Student Section")
    end

    it "sections are paginated when there are many sections in the list" do
      15.times do |x|
        @course.course_sections.create!(name: "Sections to Paginate #{x}")
      end

      visit_course_paces_page

      expect(course_pace_table_rows.count).to eq(10)
      expect(context_table_pagination).to be_displayed

      click_context_table_page(2)

      expect(course_pace_table_rows.count).to eq(9)
    end
  end

  context "course pace table for users" do
    before :once do
      create_published_course_pace("Course Pace 1", "Module Assignment 1")
      @new_section_1 = @course.course_sections.create!(name: "New Section 1")
      @student2 = user_factory(name: "Mary Seim", active_all: true, active_state: "active", section: @new_section_1)
      @course.enroll_user(@student2, "StudentEnrollment", enrollment_state: "active")
      # We need to run jobs because its progress gets stuck on the landing page otherwise!
      run_jobs
    end

    it "includes all students enrolled in the course" do
      visit_course_paces_page
      click_student_tab

      expect(course_pace_table_rows.count).to eq(2)
    end

    it "user includes assigned pace and pace type" do
      create_section_pace(@new_section_1)
      student_enrollment = Enrollment.find_by(user_id: @student2.id)
      create_student_pace(student_enrollment)

      visit_course_paces_page
      click_student_tab

      expect(context_row("Mary Seim").text).to include("Mary Seim Individual")
    end

    it "sections are paginated when there are many sections in the list" do
      create_users_in_course(@course, 15, return_type: :record)
      # We need to run jobs because its progress gets stuck on the landing page otherwise!
      run_jobs

      visit_course_paces_page
      click_student_tab

      expect(course_pace_table_rows.count).to eq(10)
      expect(context_table_pagination).to be_displayed

      click_context_table_page(2)

      expect(course_pace_table_rows.count).to eq(7)
    end

    it "navigates to the student's individual pace for editing" do
      student_enrollment = Enrollment.find_by(user_id: @student.id)
      create_student_pace(student_enrollment)

      visit_course_paces_page
      click_student_tab
      click_context_link(@student.name)

      expect(apply_or_create_pace_button.text).to eq("Apply Changes")
      expect(course_pace_title.text).to include("Student Pace: #{@student.name}")
    end
  end
end
