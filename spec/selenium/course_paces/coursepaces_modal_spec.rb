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

describe "course pace page" do
  include_context "in-process server selenium tests"
  include CoursePacesCommonPageObject
  include CoursePacesPageObject
  include CoursesHomePage
  include CoursePacesLandingPageObject

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

  context "course paces bring up modal" do
    it "navigates to the course paces modal when Get Started clicked" do
      visit_course_paces_page

      click_get_started_button

      expect(course_pace_settings_button).to be_displayed
    end

    it "navigates to course paces modal when Create Default Pace is clicked" do
      visit_course_paces_page

      click_create_default_pace_button

      expect(course_pace_settings_button).to be_displayed
    end
  end

  context "remove course pace button" do
    before :once do
      create_published_course_pace("Course Pace 1", "Module Assignment 1")
    end

    it "does not render Remove Pace button for default pace" do
      visit_course_paces_page

      click_create_default_pace_button

      expect(element_exists?(remove_pace_button_selector)).to be_falsey
    end

    it "does not render Remove Pace button for unpublished section pace" do
      @course.course_sections.create!(name: "New Section")

      visit_course_paces_page

      click_context_link("New Section")

      expect(element_exists?(remove_pace_button_selector)).to be_falsey
    end

    it "does not render Remove Pace button for unpublished student pace" do
      visit_course_paces_page

      click_student_tab

      click_context_link(@student.name)

      expect(element_exists?(remove_pace_button_selector)).to be_falsey
    end

    it "renders Remove Pace button for published section pace" do
      course_section = @course.course_sections.create!(name: "New Section")
      create_section_pace(course_section)

      visit_course_paces_page

      click_context_link("New Section")
      expect(element_exists?(remove_pace_button_selector)).to be_truthy
    end

    it "renders Remove Pace button for published student pace" do
      student_enrollment = Enrollment.find_by(user_id: @student.id)
      create_student_pace(student_enrollment)

      visit_course_paces_page

      click_student_tab

      click_context_link(@student.name)
      expect(element_exists?(remove_pace_button_selector)).to be_truthy
    end
  end

  context "Remove Pace Modal" do
    before :once do
      create_published_course_pace("Course Pace 1", "Module Assignment 1")
    end

    it "brings up the remove pace modal for Section pace when Remove Pace button clicked" do
      course_section = @course.course_sections.create!(name: "New Section")
      create_section_pace(course_section)

      visit_course_paces_page

      click_context_link("New Section")
      click_remove_pace_button

      expect(remove_pace_modal(:section)).to be_displayed
    end

    it "brings up the remove pace modal for Student pace when Remove Pace button clicked" do
      student_enrollment = Enrollment.find_by(user_id: @student.id)
      create_student_pace(student_enrollment)

      visit_course_paces_page

      click_student_tab
      click_context_link(@student.name)
      click_remove_pace_button

      expect(remove_pace_modal(:student)).to be_displayed
    end

    it "cancels out of remove pace modal with Cancel button without removing pace" do
      course_section = @course.course_sections.create!(name: "New Section")
      create_section_pace(course_section)

      visit_course_paces_page

      click_context_link("New Section")
      click_remove_pace_button
      click_remove_pace_modal_cancel

      expect(element_exists?(remove_pace_modal_selector(:section))).to be_falsey
      expect(publish_status.text).to eq("No pending changes to apply")
    end

    it "cancels out of remove pace modal with X button without removing pace" do
      student_enrollment = Enrollment.find_by(user_id: @student.id)
      create_student_pace(student_enrollment)

      visit_course_paces_page

      click_student_tab
      click_context_link(@student.name)
      click_remove_pace_button
      click_remove_pace_modal_x

      expect(element_exists?(remove_pace_modal_selector(:student))).to be_falsey
      expect(publish_status.text).to eq("No pending changes to apply")
    end

    it "removes section pace with Remove button and returns to default" do
      course_section = @course.course_sections.create!(name: "New Section")
      create_section_pace(course_section)

      visit_course_paces_page

      click_context_link("New Section")
      click_remove_pace_button
      click_remove_pace_modal_remove

      expect(element_exists?(remove_pace_modal_selector(:section))).to be_falsey
      expect(create_default_pace_button).to be_displayed
    end

    it "removes student pace with Remove button and returns to default" do
      student_enrollment = Enrollment.find_by(user_id: @student.id)
      create_student_pace(student_enrollment)

      visit_course_paces_page

      click_student_tab
      click_context_link(@student.name)
      click_remove_pace_button
      click_remove_pace_modal_remove

      expect(element_exists?(remove_pace_modal_selector(:student))).to be_falsey
      expect(create_default_pace_button).to be_displayed
    end
  end

  context "course pace header statistics" do
    before :once do
      @new_section_1 = @course.course_sections.create!(name: "New Section 1")
      @student2 = user_factory(name: "Mary Seim", active_all: true, active_state: "active")
      student_enrollment = @course.enroll_user(@student2, "StudentEnrollment", enrollment_state: "active")
      student_enrollment.course_section = @new_section_1
      student_enrollment.save!
      # We need to run jobs because its progress gets stuck on the landing page otherwise!
      run_jobs
    end

    it "shows the potential number of students in unpublished pace" do
      visit_course_paces_page

      click_create_default_pace_button

      expect(pace_info.text).to include("2")
    end

    it "shows the actual number of students in published default pace" do
      skip("LS-3608 this is broken right now")
    end

    it "shows the actual number of students in a section pace" do
      create_published_course_pace("Course Pace 1", "Module Assignment 1")
      create_section_pace(@new_section_1)

      visit_course_paces_page
      click_context_link(@new_section_1.name)

      expect(pace_info.text).to include("1")
    end

    it "shows the number of assignments in the course pace" do
      @course_module = create_course_module("New Module", "active")
      @assignment = create_assignment(@course, "Module Assignment", "Module Assignment Description", 10, "published")
      @module_item = @course_module.add_item(id: @assignment.id, type: "assignment")
      create_published_course_pace("Course Pace 1", "Module Assignment 1")

      visit_course_paces_page
      click_context_link(@new_section_1.name)

      expect(course_pace_assignment_info.text).to include("2")
    end

    it "shows the potential start and end data information in an unpublished course pace" do
      create_published_course_pace("Course Pace 1", "Module Assignment 1")

      visit_course_paces_page
      click_context_link(@new_section_1.name)

      # There's probably a better regex here
      expect(new_course_pace_start_date.text).to include("Determined by course start date")
      expect(new_course_pace_end_date.text).to include("Required end date")
    end

    it "shows the duration based on start and end dates in published course pace" do
      create_published_course_pace("Course Pace 1", "Module Assignment 1")

      visit_course_paces_page
      click_context_link(@new_section_1.name)
      # There's probably a better regex here
      expect(duration_info.text).to include("weeks")
      expect(duration_info.text).to include("day")
    end
  end
end
