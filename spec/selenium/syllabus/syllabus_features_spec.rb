# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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
require_relative "../helpers/public_courses_context"
require_relative "../helpers/files_common"
require_relative "../helpers/wiki_and_tiny_common"
require_relative "../rcs/pages/rce_next_page"
require_relative "pages/syllabus_page"

describe "course syllabus" do
  include_context "in-process server selenium tests"
  include FilesCommon
  include WikiAndTinyCommon
  include RCENextPage
  include CourseSyllabusPage

  def add_assignment(title, points)
    # assignment data
    assignment = assignment_model({
                                    course: @course,
                                    title:,
                                    due_at: nil,
                                    points_possible: points,
                                    submission_types: "online_text_entry",
                                    assignment_group: @group
                                  })
    rubric_model
    @association = @rubric.associate_with(assignment, @course, purpose: "grading")
    assignment.reload
  end

  context "as a teacher" do
    before do
      stub_rcs_config
      course_with_teacher_logged_in
      @group = @course.assignment_groups.create!(name: "first assignment group")
      @assignment_1 = add_assignment("first assignment title", 50)
      @assignment_2 = add_assignment("second assignment title", 100)

      get "/courses/#{@course.id}/assignments/syllabus"
      wait_for_ajaximations
    end

    it "confirms existing assignments and dates are correct", priority: "1" do
      assignment_details = ff(".name")
      expect(assignment_details[0].text.strip).to eq "Assignment\n" + @assignment_1.title
      expect(assignment_details[1].text.strip).to eq "Assignment\n" + @assignment_2.title
    end

    it "edits the description", priority: "1" do
      new_description = "new syllabus description"
      wait_for_new_page_load { f(".edit_syllabus_link").click }
      edit_form = f("#edit_course_syllabus_form")
      wait_for_tiny(f("#edit_course_syllabus_form"))
      type_in_tiny("#course_syllabus_body", new_description)
      submit_form(edit_form)
      wait_for_ajaximations

      expect(f("#course_syllabus").text).to eq new_description
    end

    it "inserts a file using RCE in the syllabus", custom_timeout: 30, priority: "1" do
      file = @course.attachments.create!(display_name: "text_file.txt", uploaded_data: default_uploaded_data)
      file.context = @course
      file.save!
      get "/courses/#{@course.id}/assignments/syllabus"
      f(".edit_syllabus_link").click
      add_file_to_rce_next
      submit_form(".form-actions")
      wait_for_ajax_requests
      expect(fln("text_file.txt")).to be_displayed
    end

    it "validates Jump to Today works on the mini calendar", priority: "1" do
      2.times { f(".next_month_link").click }
      f(".jump_to_today_link").click
      expect(f(".mini_month .today")).to have_attribute("id", "mini_day_#{Time.zone.now.strftime("%Y_%m_%d")}")
    end

    it "sets focus to the Jump to Today link after clicking Edit the Description", priority: "2" do
      f(".edit_syllabus_link").click
      check_element_has_focus(f(".jump_to_today_link"))
    end
  end

  context "when a public course is accessed" do
    include_context "public course as a logged out user"

    it "displays course syllabus", priority: "1" do
      get "/courses/#{public_course.id}/assignments/syllabus"
      expect(f("#course_syllabus")).to be_displayed
    end
  end

  context "as a student in a paced course" do
    before do
      course_with_student_logged_in
      @course.enable_course_paces = true
      @course.save!
    end

    it "shows the course summary and not the paced course notice" do
      get "/courses/#{@course.id}/assignments/syllabus"
      expect(f("table#syllabus")).to be_displayed
      expect(f("#syllabusContainer")).not_to contain_css(course_pacing_notice_selector)
    end
  end
end
