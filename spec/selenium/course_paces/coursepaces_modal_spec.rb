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
      get "/courses/#{@course.id}/course_pacing"

      click_get_started_button

      expect(course_pace_settings_button).to be_displayed
    end

    it "navigates to course paces modal when Create Default Pace is clicked" do
      get "/courses/#{@course.id}/course_pacing"

      click_create_default_pace_button

      expect(course_pace_settings_button).to be_displayed
    end
  end

  context "remove course pace button" do
    before :once do
      create_published_course_pace("Course Pace 1", "Module Assignment 1")
    end

    it "does not render Remove Pace button for default pace" do
      get "/courses/#{@course.id}/course_pacing"

      click_create_default_pace_button

      expect(element_exists?(remove_pace_button_selector)).to be_falsey
    end

    it "does not render Remove Pace button for unpublished section pace" do
      @course.course_sections.create!(name: "New Section")

      get "/courses/#{@course.id}/course_pacing"

      click_context_link("New Section")

      expect(element_exists?(remove_pace_button_selector)).to be_falsey
    end

    it "does not render Remove Pace button for unpublished student pace" do
      get "/courses/#{@course.id}/course_pacing"

      click_student_tab

      click_context_link(@student.name)

      expect(element_exists?(remove_pace_button_selector)).to be_falsey
    end

    it "renders Remove Pace button for published section pace" do
      course_section = @course.course_sections.create!(name: "New Section")
      create_section_pace(course_section)

      get "/courses/#{@course.id}/course_pacing"

      click_context_link("New Section")
      expect(element_exists?(remove_pace_button_selector)).to be_truthy
    end

    it "renders Remove Pace button for published student pace" do
      student_enrollment = Enrollment.find_by(user_id: @student.id)
      create_student_pace(student_enrollment)

      get "/courses/#{@course.id}/course_pacing"

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

      get "/courses/#{@course.id}/course_pacing"

      click_context_link("New Section")
      click_remove_pace_button

      expect(remove_pace_modal(:section)).to be_displayed
    end

    it "brings up the remove pace modal for Student pace when Remove Pace button clicked" do
      student_enrollment = Enrollment.find_by(user_id: @student.id)
      create_student_pace(student_enrollment)

      get "/courses/#{@course.id}/course_pacing"

      click_student_tab
      click_context_link(@student.name)
      click_remove_pace_button

      expect(remove_pace_modal(:student)).to be_displayed
    end

    it "cancels out of remove pace modal with Cancel button without removing pace" do
      course_section = @course.course_sections.create!(name: "New Section")
      create_section_pace(course_section)

      get "/courses/#{@course.id}/course_pacing"

      click_context_link("New Section")
      click_remove_pace_button
      click_remove_pace_modal_cancel

      expect(element_exists?(remove_pace_modal_selector(:section))).to be_falsey
      expect(publish_status.text).to eq("No pending changes to apply")
    end

    it "cancels out of remove pace modal with X button without removing pace" do
      student_enrollment = Enrollment.find_by(user_id: @student.id)
      create_student_pace(student_enrollment)

      get "/courses/#{@course.id}/course_pacing"

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

      get "/courses/#{@course.id}/course_pacing"

      click_context_link("New Section")
      click_remove_pace_button
      click_remove_pace_modal_remove

      expect(element_exists?(remove_pace_modal_selector(:section))).to be_falsey
      expect(create_default_pace_button).to be_displayed
    end

    it "removes student pace with Remove button and returns to default" do
      student_enrollment = Enrollment.find_by(user_id: @student.id)
      create_student_pace(student_enrollment)

      get "/courses/#{@course.id}/course_pacing"

      click_student_tab
      click_context_link(@student.name)
      click_remove_pace_button
      click_remove_pace_modal_remove

      expect(element_exists?(remove_pace_modal_selector(:student))).to be_falsey
      expect(create_default_pace_button).to be_displayed
    end
  end
end
