# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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
#

require_relative "../../helpers/gradebook_common"
require_relative "../pages/gradebook_cells_page"
require_relative "../pages/enhanced_srgb_page"
require_relative "../pages/grading_curve_page"

describe "Screenreader Gradebook" do
  include_context "in-process server selenium tests"
  include_context "reusable_gradebook_course"
  include GradebookCommon

  let(:default_gradebook) { "/courses/#{@course.id}/gradebook/change_gradebook_version?version=2" }
  let(:view_grading_history) { f("a[href='/courses/#{@course.id}/gradebook/history']") }
  let(:assign1_default_points) { 1 }
  let(:assignment_default_points) { 20 }

  def active_element
    driver.switch_to.active_element
  end

  def basic_percent_setup(num = 1)
    init_course_with_students(num)
    user_session(@teacher)
    @course.assignments.create!(
      title: "Test 1",
      submission_types: "online_text_entry",
      points_possible: 20,
      grading_type: "percent"
    )
  end

  def basic_point_setup(num = 1)
    init_course_with_students(num)
    user_session(@teacher)
    @curve_assignment = @course.assignments.create!(
      title: "Test 1",
      submission_types: "online_text_entry",
      points_possible: 20,
      grading_type: "points"
    )
  end

  def simple_setup(student_number = 2)
    init_course_with_students(student_number)
    user_session(@teacher)
    @course.assignment_groups.create! name: "Group 1"
    @course.assignment_groups.create! name: "Group 2"
    @assign1 = @course.assignments.create!(
      title: "Test 1",
      points_possible: assignment_default_points,
      assignment_group: @course.assignment_groups[0]
    )
    @assign2 = @course.assignments.create!(
      title: "Test 2",
      points_possible: assignment_default_points,
      assignment_group: @course.assignment_groups[1]
    )

    @grade_array = %w[15 12 11 3]
  end

  def simple_grade
    @assign1.grade_student(@students[0], grade: @grade_array[0], grader: @teacher)
    @assign1.grade_student(@students[1], grade: @grade_array[1], grader: @teacher)
    @assign2.grade_student(@students[0], grade: @grade_array[2], grader: @teacher)
    @assign2.grade_student(@students[1], grade: @grade_array[3], grader: @teacher)
  end

  it "can select a student" do
    simple_setup
    simple_grade
    EnhancedSRGB.visit(@course.id)
    student_dropdown_options = ["No Student Selected", @students[0].sortable_name, @students[1].sortable_name]
    expect(EnhancedSRGB.student_dropdown_options).to eq(student_dropdown_options)

    click_option(EnhancedSRGB.student_dropdown, @students[0].sortable_name)
    assignment_points = ["75% (#{@grade_array[0]} / 20)", "55.0% (#{@grade_array[2]} / 20)"]
    expect(EnhancedSRGB.assign_subtotal_grade.map(&:text)).to eq(assignment_points)

    click_option(EnhancedSRGB.student_dropdown, @students[1].sortable_name)
    assignment_points = ["60% (#{@grade_array[1]} / 20)", "15% (#{@grade_array[3]} / 20)"]
    expect(EnhancedSRGB.assign_subtotal_grade.map(&:text)).to eq(assignment_points)
  end

  it "can select a student using buttons" do
    init_course_with_students(3)
    user_session(@teacher)
    EnhancedSRGB.visit(@course.id)

    # first student
    expect(EnhancedSRGB.previous_student.attribute("disabled")).to be_truthy
    EnhancedSRGB.next_student.click
    expect(EnhancedSRGB.student_information_name).to include_text(@students[0].name)
    # second student
    EnhancedSRGB.next_student.click
    expect(EnhancedSRGB.student_information_name).to include_text(@students[1].name)

    # third student
    EnhancedSRGB.next_student.click
    expect(EnhancedSRGB.next_student.attribute("disabled")).to be_truthy
    expect(EnhancedSRGB.student_information_name).to include_text(@students[2].name)
    expect(EnhancedSRGB.previous_student).to eq driver.switch_to.active_element

    # click twice to go back to first student
    EnhancedSRGB.previous_student.click
    EnhancedSRGB.previous_student.click
    expect(EnhancedSRGB.student_information_name).to include_text(@students[0].name)
    EnhancedSRGB.previous_student.click
    expect(EnhancedSRGB.next_student).to eq driver.switch_to.active_element
  end

  it "can select an assignment using buttons" do
    simple_setup
    EnhancedSRGB.visit(@course.id)

    expect(EnhancedSRGB.previous_assignment.attribute("disabled")).to be_truthy
    expect(EnhancedSRGB.next_assignment.attribute("disabled")).not_to be_truthy

    EnhancedSRGB.next_assignment.click
    EnhancedSRGB.next_assignment.click
    expect(EnhancedSRGB.previous_assignment.attribute("disabled")).not_to be_truthy
    expect(EnhancedSRGB.next_assignment.attribute("disabled")).to be_truthy

    EnhancedSRGB.previous_assignment.click
    EnhancedSRGB.previous_assignment.click
    expect(EnhancedSRGB.previous_assignment.attribute("disabled")).to be_truthy
  end

  it "links to assignment show page" do
    simple_setup
    simple_grade
    @submission = @assign1.submit_homework(@students[0], body: "student submission")
    EnhancedSRGB.visit(@course.id)
    EnhancedSRGB.select_assignment(@assign1)
    wait_for_new_page_load(EnhancedSRGB.assignment_link.click)

    expect(driver.current_url).to include("/courses/#{@course.id}/assignments/#{@assign1.id}")
  end

  it "sets default grade" do
    simple_setup(2)
    EnhancedSRGB.visit(@course.id)
    click_option(EnhancedSRGB.student_dropdown, @students[0].sortable_name)
    EnhancedSRGB.select_assignment(@assign1)

    EnhancedSRGB.default_grade.click
    replace_content(EnhancedSRGB.default_grade_input, assign1_default_points)
    EnhancedSRGB.default_grade_submit_button.click

    get(default_gradebook)
    expect(Gradebook::Cells.get_grade(@students[0], @assign1)).to eq("1")
    expect(Gradebook::Cells.get_grade(@students[1], @assign1)).to eq("1")
  end

  it "can select an assignment" do
    a1 = basic_percent_setup
    a2 = @course.assignments.create!(
      title: "Test 2",
      points_possible: 20
    )

    a1.grade_student(@students[0], grade: 14, grader: @teacher)
    EnhancedSRGB.visit(@course.id)

    expect(EnhancedSRGB.assignment_dropdown_options).to eq ["No Assignment Selected", a1.name, a2.name]
    EnhancedSRGB.select_assignment(a1)
    expect(EnhancedSRGB.assignment_link).to include_text(a1.name)
    expect(EnhancedSRGB.assignment_submission_info).to include_text("Online text entry")
  end

  it "displays/removes warning message for resubmitted assignments" do
    assignment = basic_percent_setup
    assignment.submit_homework(@students[0], submission_type: "online_text_entry", body: "Hello!")
    assignment.grade_student(@students[0], grade: 12, grader: @teacher)
    assignment.submit_homework(@students[0], submission_type: "online_text_entry", body: "Hello again!")

    user_session(@teacher)
    EnhancedSRGB.visit(@course.id)
    EnhancedSRGB.select_assignment(assignment)
    EnhancedSRGB.select_student(@students[0])
    expect(f(".resubmitted_assignment_label")).to be_displayed

    replace_content EnhancedSRGB.main_grade_input, "15\t"
    expect(f("#content")).not_to contain_css(".resubmitted_assignment_label")
  end

  it "grades match default gradebook grades" do
    a1 = basic_percent_setup
    a2 = @course.assignments.create!(
      title: "Test 2",
      points_possible: 20
    )

    grades = [75, 12]

    get(default_gradebook)
    Gradebook::Cells.edit_grade(@students[0], a1, grades[0])
    EnhancedSRGB.visit(@course.id)
    EnhancedSRGB.select_student(@students[0])
    EnhancedSRGB.select_assignment(a1)

    expect(EnhancedSRGB.main_grade_input).to have_value("#{grades[0]}%")
    expect(EnhancedSRGB.final_grade).to include_text("#{grades[0]}% (15 / 20 points)")

    EnhancedSRGB.select_assignment(a2)
    EnhancedSRGB.enter_grade(grades[1])
    get(default_gradebook)

    expect(Gradebook::Cells.get_grade(@students[0], a2)).to eq(grades[1].to_s)
  end

  it "can message students who..." do
    a1 = basic_percent_setup
    EnhancedSRGB.visit(@course.id)

    EnhancedSRGB.select_assignment(a1)
    EnhancedSRGB.message_students_button.click
    EnhancedSRGB.message_students_input.send_keys("Hello!")

    expect(EnhancedSRGB.message_students_submit_button).to be_enabled
  end

  it "has total graded submission" do
    assignment = basic_percent_setup(2)
    assignment.grade_student(@students[0], grade: 15, grader: @teacher)
    assignment.grade_student(@students[1], grade: 5, grader: @teacher)

    EnhancedSRGB.visit(@course.id)
    EnhancedSRGB.select_student(@students[0])
    EnhancedSRGB.select_assignment(assignment)
    expect(EnhancedSRGB.assignment_submission_info).to include_text("Graded submissions: 2")
    expect(EnhancedSRGB.assignment_points_possible).to include_text("20")
    expect(EnhancedSRGB.assignment_average).to include_text("10")
    expect(EnhancedSRGB.assignment_max).to include_text("15")
    expect(EnhancedSRGB.assignment_min).to include_text("5")
  end

  context "as a teacher" do
    before(:once) do
      gradebook_data_setup
    end

    before do
      user_session(@teacher)
    end

    it "shows sections in drop-down" do
      sections = []
      2.times do |i|
        sections << @course.course_sections.create!(name: "other section #{i}")
      end

      EnhancedSRGB.visit(@course.id)
      expect(EnhancedSRGB.section_select_options).to include(sections[0].name)
      expect(EnhancedSRGB.section_select_options).to include(sections[1].name)
    end

    it "shows history" do
      EnhancedSRGB.visit(@course.id)

      view_grading_history.click
      expect(driver.page_source).to include("Gradebook History")
      expect(driver.current_url).to include("gradebook/history")
    end

    it "shows all drop down options" do
      EnhancedSRGB.visit(@course.id)

      expect(EnhancedSRGB.sort_assignments_select_options).to eq(["By Assignment Group and Position", "Alphabetically", "By Due Date"])
    end

    it "keeps the assignment group arrangement choice between reloads" do
      EnhancedSRGB.visit(@course.id)
      EnhancedSRGB.sort_assignments_by(EnhancedSRGB.assignment_group_sort_string)
      refresh_page

      expect(EnhancedSRGB.assignment_sort_order).to eq(EnhancedSRGB.assignment_group_sort_value)
    end

    it "keeps the assignment alphabetical arrangement choice between reloads" do
      EnhancedSRGB.visit(@course.id)
      EnhancedSRGB.sort_assignments_by(EnhancedSRGB.assignment_alpha_sort_string)
      refresh_page

      expect(EnhancedSRGB.assignment_sort_order).to eq(EnhancedSRGB.assignment_alpha_sort_value)
    end

    it "keeps the assignment due date arrangement choice between reloads" do
      EnhancedSRGB.visit(@course.id)
      EnhancedSRGB.sort_assignments_by(EnhancedSRGB.assignment_due_date_sort_string)
      refresh_page

      expect(EnhancedSRGB.assignment_sort_order).to eq(EnhancedSRGB.assignment_due_date_sort_value)
    end

    it "focuses on accessible elements when setting default grades" do
      EnhancedSRGB.visit(@course.id)
      EnhancedSRGB.select_assignment(@second_assignment)

      # When the modal opens the close button should have focus
      # When the modal closes by the close button
      # the "set default grade" button should have focus
      EnhancedSRGB.default_grade.click
      active_element.click

      check_element_has_focus(EnhancedSRGB.default_grade)

      # When the modal closes by setting a grade
      # the "set default grade" button should have focus
      EnhancedSRGB.default_grade.click
      EnhancedSRGB.default_grade_input.send_keys("1")
      EnhancedSRGB.default_grade_submit_button.click

      check_element_has_focus(EnhancedSRGB.default_grade)
    end

    describe "Download Submissions Button" do
      before(:once) do
        @first_assignment.update!(submission_types: "media_recording")
        @third_assignment.update!(submission_types: "online_text_entry,media_recording")
        @third_assignment.submit_homework(@student_1, body: "Can you click?")
      end

      # The Download Submission button should be displayed for online_upload,
      # online_text_entry, online_url, and online_quiz assignments. It should
      # not be displayed for any other types.
      it "is displayed for online assignments" do
        EnhancedSRGB.visit(@course.id)
        EnhancedSRGB.select_assignment(@second_assignment)

        expect(EnhancedSRGB.download_submissions_button).to be_present
      end

      it "is not displayed for assignments which are not submitted online" do
        EnhancedSRGB.visit(@course.id)
        EnhancedSRGB.select_assignment(@assignment)

        expect(EnhancedSRGB.assignment_information).not_to include_text("Download all Submissions")
      end

      it "is displayed for assignments which allow both online and non-online submittion" do
        EnhancedSRGB.visit(@course.id)
        EnhancedSRGB.select_assignment(@third_assignment)

        expect(EnhancedSRGB.download_submissions_button).to be_present
      end
    end
  end

  context "curving grades" do
    it "curves grades" do
      basic_point_setup(3)

      grades = [12, 10, 11]
      3.times { |num| @curve_assignment.grade_student(@students[num], grade: grades[num], grader: @teacher) }

      EnhancedSRGB.visit(@course.id)
      EnhancedSRGB.select_assignment(@curve_assignment)
      EnhancedSRGB.curve_grade_button.click
      # verify that the modal pops up
      curve_form = GradingCurvePage.new
      expect(curve_form.grading_curve_dialog_title.text).to eq("Curve Grade for #{@curve_assignment.name}")

      curve_form.edit_grade_curve("10")
      curve_form.curve_grade_submit
      accept_alert

      expect(EnhancedSRGB.assignment_average).to include_text("13")
      expect(EnhancedSRGB.assignment_max).to include_text("20")
      expect(EnhancedSRGB.assignment_min).to include_text("8")
    end
  end
end
