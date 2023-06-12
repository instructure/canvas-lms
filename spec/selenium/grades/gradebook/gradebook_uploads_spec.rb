# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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
require_relative "../pages/gradebook_page"

describe "Gradebook - uploads" do
  include_context "in-process server selenium tests"

  before do
    course_with_teacher_logged_in(active_all: 1, username: "teacher@example.com")
    @student = user_factory(username: "student@example.com", active_all: 1)
    @course.enroll_student(@student).accept!

    Gradebook.visit_upload(@course)
  end

  def gradebook_file(filename, *rows)
    get_file(filename, rows.join("\n"))
  end

  def assert_assignment_is_highlighted
    expect(ff(".left-highlight").length).to eq 1
    expect(ff(".right-highlight").length).to eq 1
  end

  def assert_assignment_is_not_highlighted
    expect(f("#content")).not_to contain_css(".left-highlight")
    expect(f("#content")).not_to contain_css(".right-highlight")
  end

  it "updates grades for assignments with GPA Scale grading type correctly", priority: "1" do
    assignment = @course.assignments.create!(title: "GPA Scale Assignment",
                                             grading_type: "gpa_scale",
                                             points_possible: 5)
    assignment.grade_student(@student, grade: "D", grader: @teacher)
    _filename, fullpath, _data = gradebook_file("gradebook0.csv",
                                                "Student Name,ID,Section,GPA Scale Assignment",
                                                "User,#{@student.id},,B-")
    Gradebook.grades_uploaded_data.send_keys(fullpath)
    wait_for_new_page_load { Gradebook.grades_new_upload.submit }
    run_jobs
    Gradebook.wait_for_spinner
    wait_for_new_page_load(true) { submit_form("#gradebook_grid_form") }
    run_jobs
    expect(assignment.submissions.last.grade).to eq "B-"
  end

  it "says no changes if no changes", priority: "1" do
    assignment = @course.assignments.create!(title: "Assignment 1")
    assignment.grade_student(@student, grade: 10, grader: @teacher)

    _filename, fullpath, _data = gradebook_file("gradebook1.csv",
                                                "Student Name,ID,Section,Assignment 1",
                                                "User,#{@student.id},,10")
    Gradebook.grades_uploaded_data.send_keys(fullpath)
    wait_for_new_page_load { Gradebook.grades_new_upload.submit }
    run_jobs
    Gradebook.wait_for_spinner

    expect(f("#gradebook_importer_resolution_section")).not_to be_displayed
  end

  it "shows only changed assignment", priority: "1" do
    assignment1 = @course.assignments.create!(title: "Assignment 1")
    assignment1.grade_student(@student, grade: 10, grader: @teacher)
    assignment2 = @course.assignments.create!(title: "Assignment 2")
    assignment2.grade_student(@student, grade: 10, grader: @teacher)

    _filename, fullpath, _data = gradebook_file("gradebook.csv",
                                                "Student Name,ID,Section,Assignment 1,Assignment 2",
                                                "User,#{@student.id},,10,9")
    Gradebook.grades_uploaded_data.send_keys(fullpath)
    wait_for_new_page_load { Gradebook.grades_new_upload.submit }
    run_jobs
    Gradebook.wait_for_spinner

    expect(f("#gradebook_importer_resolution_section")).not_to be_displayed
    expect(f("#no_changes_detected")).not_to be_displayed

    expect(ff(".slick-header-column.assignment").length).to eq 1
    expect(f("#assignments_without_changes_alert")).to be_displayed
  end

  it "shows a new assignment", priority: "1" do
    _filename, fullpath, _data = gradebook_file("gradebook3.csv",
                                                "Student Name,ID,Section,New Assignment",
                                                "User,#{@student.id},,0")
    Gradebook.grades_uploaded_data.send_keys(fullpath)
    wait_for_new_page_load { Gradebook.grades_new_upload.submit }
    run_jobs
    Gradebook.wait_for_spinner

    expect(f("#gradebook_importer_resolution_section")).to be_displayed

    expect(ff(".assignment_section #assignment_resolution_template").length).to eq 1
    expect(f(".assignment_section #assignment_resolution_template .title").text).to eq "New Assignment"

    click_option(".assignment_section #assignment_resolution_template select", "new", :value)

    submit_form("#gradebook_importer_resolution_section")

    expect(f("#no_changes_detected")).not_to be_displayed

    expect(ff(".slick-header-column.assignment").length).to eq 1
    expect(f("#assignments_without_changes_alert")).not_to be_displayed

    assignment_count = @course.assignments.count
    wait_for_new_page_load(true) { submit_form("#gradebook_grid_form") }
    run_jobs
    expect(@course.assignments.count).to eql(assignment_count + 1)
    assignment = @course.assignments.order(:created_at).last
    submission = assignment.submissions.last
    expect(submission.score).to eq 0
  end

  it "creates an assignment with no grades", priority: "1" do
    assignment1 = @course.assignments.create!(title: "Assignment 1")
    assignment1.grade_student(@student, grade: 10, grader: @teacher)

    _filename, fullpath, _data = gradebook_file("gradebook.csv",
                                                "Student Name,ID,Section,Assignment 2,Assignment 1",
                                                "User,#{@student.id},,,10")
    Gradebook.grades_uploaded_data.send_keys(fullpath)
    wait_for_new_page_load { Gradebook.grades_new_upload.submit }
    run_jobs
    Gradebook.wait_for_spinner

    expect(f("#gradebook_importer_resolution_section")).to be_displayed

    expect(ff(".assignment_section #assignment_resolution_template").length).to eq 1
    expect(f(".assignment_section #assignment_resolution_template .title").text).to eq "Assignment 2"

    click_option(".assignment_section #assignment_resolution_template select", "new", :value)

    submit_form("#gradebook_importer_resolution_section")

    expect(f("#no_changes_detected")).not_to be_displayed

    expect(ff(".slick-header-column.assignment").length).to eq 1

    assignment_count = @course.assignments.count
    wait_for_new_page_load { submit_form("#gradebook_grid_form") }
    run_jobs
    expect(@course.assignments.count).to eql(assignment_count + 1)
    assignment = @course.assignments.order(:created_at).last
    expect(assignment.name).to eq "Assignment 2"
    expect(assignment.submissions.having_submission.count).to be 0
    expect(f("#gradebook_wrapper")).to be_displayed
  end

  it "says no changes if no changes after matching assignment" do
    assignment = @course.assignments.create!(title: "Assignment 1")
    assignment.grade_student(@student, grade: 10, grader: @teacher)

    _filename, fullpath, _data = gradebook_file("gradebook4.csv",
                                                "Student Name,ID,Section,Assignment 2",
                                                "User,#{@student.id},,10")
    Gradebook.grades_uploaded_data.send_keys(fullpath)
    wait_for_new_page_load { Gradebook.grades_new_upload.submit }
    run_jobs
    Gradebook.wait_for_spinner

    expect(f("#gradebook_importer_resolution_section")).to be_displayed

    expect(ff(".assignment_section #assignment_resolution_template").length).to eq 1
    expect(f(".assignment_section #assignment_resolution_template .title").text).to eq "Assignment 2"

    click_option(".assignment_section #assignment_resolution_template select", assignment.id.to_s, :value)

    submit_form("#gradebook_importer_resolution_section")

    expect(f("#no_changes_detected")).to be_displayed
  end

  it "shows assignment with changes after matching assignment", priority: "1" do
    assignment1 = @course.assignments.create!(title: "Assignment 1")
    assignment1.grade_student(@student, grade: 10, grader: @teacher)
    assignment2 = @course.assignments.create!(title: "Assignment 2")
    assignment2.grade_student(@student, grade: 10, grader: @teacher)

    _filename, fullpath, _data = gradebook_file("gradebook5.csv",
                                                "Student Name,ID,Section,Assignment 1,Assignment 3",
                                                "User,#{@student.id},,10,9")
    Gradebook.grades_uploaded_data.send_keys(fullpath)
    wait_for_new_page_load { Gradebook.grades_new_upload.submit }
    run_jobs
    Gradebook.wait_for_spinner

    expect(f("#gradebook_importer_resolution_section")).to be_displayed

    expect(ff(".assignment_section #assignment_resolution_template").length).to eq 1
    expect(f(".assignment_section #assignment_resolution_template .title").text).to eq "Assignment 3"

    click_option(".assignment_section #assignment_resolution_template select", assignment2.id.to_s, :value)

    submit_form("#gradebook_importer_resolution_section")

    expect(f("#no_changes_detected")).not_to be_displayed

    expect(ff(".slick-header-column.assignment").length).to eq 1
    expect(f("#assignments_without_changes_alert")).to be_displayed
  end

  it "says no changes after matching student", priority: "1" do
    assignment = @course.assignments.create!(title: "Assignment 1")
    assignment.grade_student(@student, grade: 10, grader: @teacher)

    _filename, fullpath, _data = gradebook_file("gradebook6.csv",
                                                "Student Name,ID,Section,Assignment 1",
                                                "Student,,,10")
    Gradebook.grades_uploaded_data.send_keys(fullpath)
    wait_for_new_page_load { Gradebook.grades_new_upload.submit }
    run_jobs
    Gradebook.wait_for_spinner

    expect(f("#gradebook_importer_resolution_section")).to be_displayed

    expect(ff(".student_section #student_resolution_template").length).to eq 1
    expect(f(".student_section #student_resolution_template .name").text).to eq "Student"

    click_option(".student_section #student_resolution_template select", @student.id.to_s, :value)

    submit_form("#gradebook_importer_resolution_section")

    expect(f("#no_changes_detected")).to be_displayed
  end

  it "shows assignment with changes after matching student", priority: "1" do
    assignment1 = @course.assignments.create!(title: "Assignment 1")
    assignment1.grade_student(@student, grade: 10, grader: @teacher)
    assignment2 = @course.assignments.create!(title: "Assignment 2")
    assignment2.grade_student(@student, grade: 10, grader: @teacher)

    _filename, fullpath, _data = gradebook_file("gradebook7.csv",
                                                "Student Name,ID,Section,Assignment 1,Assignment 2",
                                                "Student,,,10,9")
    Gradebook.grades_uploaded_data.send_keys(fullpath)
    wait_for_new_page_load { Gradebook.grades_new_upload.submit }
    run_jobs
    Gradebook.wait_for_spinner

    expect(f("#gradebook_importer_resolution_section")).to be_displayed

    expect(ff(".student_section #student_resolution_template").length).to eq 1
    expect(f(".student_section #student_resolution_template .name").text).to eq "Student"

    click_option(".student_section #student_resolution_template select", @student.id.to_s, :value)

    submit_form("#gradebook_importer_resolution_section")

    expect(f("#no_changes_detected")).not_to be_displayed

    expect(ff(".slick-header-column.assignment").length).to eq 1
    expect(f("#assignments_without_changes_alert")).to be_displayed
  end

  it "highlights scores if the original grade is more than the new grade", priority: "1" do
    assignment1 = @course.assignments.create!(title: "Assignment 1")
    assignment1.grade_student(@student, grade: 10, grader: @teacher)

    _filename, fullpath, _data = gradebook_file("gradebook.csv",
                                                "Student Name,ID,Section,Assignment 1",
                                                "User,#{@student.id},,9")

    Gradebook.grades_uploaded_data.send_keys(fullpath)
    wait_for_new_page_load { Gradebook.grades_new_upload.submit }
    run_jobs
    Gradebook.wait_for_spinner

    assert_assignment_is_highlighted
  end

  it "highlights scores if the original grade is replaced by empty grade", priority: "1" do
    assignment1 = @course.assignments.create!(title: "Assignment 1")
    assignment1.grade_student(@student, grade: 10, grader: @teacher)

    _filename, fullpath, _data = gradebook_file("gradebook.csv",
                                                "Student Name,ID,Section,Assignment 1",
                                                "User,#{@student.id},,")

    Gradebook.grades_uploaded_data.send_keys(fullpath)
    wait_for_new_page_load { Gradebook.grades_new_upload.submit }
    run_jobs
    Gradebook.wait_for_spinner

    assert_assignment_is_highlighted
  end

  it "does not highlight scores if the original grade is less than the new grade", priority: "1" do
    assignment1 = @course.assignments.create!(title: "Assignment 1")
    assignment1.grade_student(@student, grade: 10, grader: @teacher)

    _filename, fullpath, _data = gradebook_file("gradebook.csv",
                                                "Student Name,ID,Section,Assignment 1",
                                                "User,#{@student.id},,100")

    Gradebook.grades_uploaded_data.send_keys(fullpath)
    wait_for_new_page_load { Gradebook.grades_new_upload.submit }
    run_jobs
    Gradebook.wait_for_spinner

    assert_assignment_is_not_highlighted
  end

  it "does not highlight scores if the assignment is excused", priority: "1" do
    assignment1 = @course.assignments.create!(title: "Assignment 1")
    assignment1.grade_student(@student, grade: 10, grader: @teacher)

    _filename, fullpath, _data = gradebook_file("gradebook.csv",
                                                "Student Name,ID,Section,Assignment 1",
                                                "User,#{@student.id},,EX")

    Gradebook.grades_uploaded_data.send_keys(fullpath)
    wait_for_new_page_load { Gradebook.grades_new_upload.submit }
    run_jobs
    Gradebook.wait_for_spinner

    assert_assignment_is_not_highlighted
  end

  describe "override grades" do
    before do
      @course1 = Course.create!
      @course1.enable_feature!(:final_grades_override)
      @course1.update!(allow_final_grade_override: true)
      @student_enrollment = student_in_course(active_all: true, course: @course1)
      @student = @student_enrollment.user
      @teacher = teacher_in_course(course: @course1, active_all: true).user
      assignment1 = @course1.assignments.create!(title: "Assignment 1")
      assignment1.grade_student(@student, grade: 10, grader: @teacher)
      @student_enrollment.scores.find_by!(course_score: true).update!(override_score: 89.1)

      user_session(@teacher)
      Gradebook.visit_upload(@course1)
    end

    it "finds changes to override scores" do
      _filename, fullpath, _data = gradebook_file("gradebook.csv",
                                                  "Student Name,ID,Section,Assignment 1,Override Score",
                                                  "User,#{@student.id},,10,100")

      Gradebook.grades_uploaded_data.send_keys(fullpath)
      wait_for_new_page_load { Gradebook.grades_new_upload.submit }
      run_jobs
      Gradebook.wait_for_spinner

      expect(f("#gradebook_importer_resolution_section")).not_to be_displayed
      expect(f("#no_changes_detected")).not_to be_displayed

      expect(ff(".slick-header-column.assignment").length).to eq 1
      expect(f("#assignments_without_changes_alert")).to be_displayed
    end
  end
end
