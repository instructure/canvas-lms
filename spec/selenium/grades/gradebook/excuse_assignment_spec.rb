# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require_relative "../../helpers/gradebook_common"
require_relative "../../helpers/groups_common"
require_relative "../pages/gradebook_page"
require_relative "../pages/gradebook_cells_page"

describe "Excuse an Assignment" do
  include_context "in-process server selenium tests"
  include GradebookCommon
  include GroupsCommon

  before do |example|
    unless example.metadata[:group]
      course_with_teacher_logged_in
      course_with_student(course: @course, active_all: true, name: "Student")
    end
  end

  context "Student view details" do
    before do
      @assignment = @course.assignments.create! title: "Excuse Me", submission_types: "online_text_entry", points_possible: 20
      @assignment.grade_student @student, excuse: true, grader: @teacher

      user_session @student
    end

    it "Assignment index displays scores as excused", priority: "1" do
      get "/courses/#{@course.id}/assignments"
      wait_for_ajaximations
      expect(f('[id^="assignment_"] span.non-screenreader').text).to eq "Excused"
    end

    it "Assignment details displays scores as excused", priority: "1" do
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      wait_for_ajaximations
      expect(f("#sidebar_content .details .header").text).to eq "Excused!"
    end

    it "Submission details displays scores as excused", priority: "1" do
      get "/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}"
      wait_for_ajaximations
      expect(f("#content span.entered_grade").text).to eq "Excused"
    end
  end

  it "Gradebook export accounts for excused assignment", priority: "1" do
    assignment = @course.assignments.create! title: "Excuse Me", points_possible: 20
    assignment.grade_student @student, excuse: true, grader: @teacher

    csv = CSV.parse(GradebookExporter.new(@course, @teacher).to_csv)
    _name, _id, _section, _sis_login_id, score = csv[-1]
    expect(score).to eq "EX"
  end

  it "Gradebook import accounts for excused assignment", priority: "1" do
    skip_if_chrome("fragile upload process")
    @course.assignments.create! title: "Excuse Me", points_possible: 20
    rows = ["Student Name,ID,Section,Excuse Me",
            "Student,#{@student.id},,EX"]
    _filename, fullpath, _data = get_file("gradebook.csv", rows.join("\n"))

    get "/courses/#{@course.id}/gradebook_uploads/new"

    f("#gradebook_upload_uploaded_data").send_keys(fullpath)
    f("#new_gradebook_upload").submit
    run_jobs
    wait_for_ajaximations
    expect(f(".canvas_1 .new-grade").text).to eq "Excused"

    submit_form("#gradebook_grid_form")
    driver.switch_to.alert.accept
    wait_for_ajaximations
    run_jobs

    get "/courses/#{@course.id}/gradebook"
    expect(f(".canvas_1 .slick-row .slick-cell:first-child").text).to eq "Excused"

    # Test case insensitivity on 'EX'
    assign = @course.assignments.create! title: "Excuse Me 2", points_possible: 20
    assign.grade_student @student, excuse: true, grader: @teacher
    rows = ["Student Name,ID,Section,Excuse Me 2",
            "Student,#{@student.id},,Ex"]
    _filename, fullpath, _data = get_file("gradebook.csv", rows.join("\n"))

    get "/courses/#{@course.id}/gradebook_uploads/new"

    f("#gradebook_upload_uploaded_data").send_keys(fullpath)
    f("#new_gradebook_upload").submit
    run_jobs
    wait_for_ajaximations

    expect(f("#no_changes_detected")).not_to be_nil
  end

  context "SpeedGrader" do
    it "can excuse complete/incomplete assignments", priority: "1" do
      assignment = @course.assignments.create! title: "Excuse Me", points_possible: 20, grading_type: "pass_fail"

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{assignment.id}"
      click_option f("#grading-box-extended"), "Excused"

      get "/courses/#{@course.id}/grades"
      expect(Gradebook::Cells.get_grade(@course.students[0], assignment)).to eq "Excused"
      expect(Gradebook::Cells.grading_cell(@course.students[0], assignment)).to contain_css(".excused")
    end

    it "excuses an assignment properly", priority: "1" do
      a1 = @course.assignments.create! title: "Excuse Me", points_possible: 20
      a2 = @course.assignments.create! title: "Don't Excuse Me", points_possible: 10
      a1.grade_student(@student, grade: 20, grader: @teacher)
      a2.grade_student(@student, grade: 5, grader: @teacher)

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{a2.id}"
      replace_content f("#grading-box-extended"), "EX", press_return: true

      get "/courses/#{@course.id}/grades"

      expect(Gradebook::Cells.get_grade(@student, a1)).to eq "20"

      # this should show 'EX' and have excused class
      expect(Gradebook::Cells.get_grade(@student, a2)).to eq "Excused"
      expect(Gradebook::Cells.grading_cell(@student, a2)).to contain_css(".excused")

      expect(Gradebook::Cells.get_total_grade(@student)).to eq "100%"
    end

    it "indicates excused assignment as graded", priority: "1" do
      assignment = @course.assignments.build
      assignment.publish

      assignment.grade_student(@student, excuse: true, grader: @teacher)

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{assignment.id}"
      expect(f("#combo_box_container .ui-selectmenu-item-icon i")).to have_class "icon-check"
      expect(f("#combo_box_container .ui-selectmenu-item-header").text).to eq "Student"
    end
  end

  shared_examples "Basic Behavior" do |view|
    context "Group Assignments", :group do
      it "preserves assignment excused status", priority: "1" do
        course_with_teacher_logged_in
        group_test_setup 4, 1, 1

        @students.each { |student| @testgroup[0].add_user student }
        @testgroup[0].save!

        assignment = @course.assignments.create!(
          title: "Group Assignment",
          group_category_id: @group_category[0].id,
          grade_group_students_individually: false,
          points_possible: 20
        )

        assignment.grade_student @students[1], excuse: true, grader: @teacher
        assignment.grade_student @students[0], grade: 15, grader: @teacher

        score_values = []

        if view == "srgb"
          get "/courses/#{@course.id}/gradebook/change_gradebook_version?version=srgb"
          click_option f("#assignment_select"), assignment.title
          next_student = f(".student_navigation button.next_object")
          4.times do
            next_student.click
            wait_for_ajaximations
            score_values << f("#student_and_assignment_grade").attribute("value")
          end
        else
          get "/courses/#{@course.id}/gradebook/"
          wait_for_ajaximations
          score_values = ff(".canvas_1 .slick-row .slick-cell:first-child").map(& :text)
        end
        expect(score_values).to eq %w[15 Excused 15 15]
      end

      it "excuses assignments on individual basis", priority: "1" do
        course_with_teacher_logged_in
        group_test_setup 2, 1, 1

        @students.each { |student| @testgroup[0].add_user student }
        @testgroup[0].save!

        a1 = @course.assignments.create!(
          title: "Group Assignment",
          group_category_id: @group_category[0].id,
          grade_group_students_individually: false,
          points_possible: 10
        )
        a2 = @course.assignments.create! title: "Assignment", points_possible: 20

        @students.each do |student|
          a1.grade_student student, grade: 5, grader: @teacher
          a2.grade_student student, grade: 20, grader: @teacher
        end

        a1.grade_student @students[1], excuse: true, grader: @teacher

        totals = []
        if view == "srgb"
          get "/courses/#{@course.id}/gradebook/change_gradebook_version?version=srgb"
          next_student = f(".student_navigation button.next_object")
          2.times do
            next_student.click
            wait_for_ajaximations
            totals << f("span.total-grade").text[/\d+(\.\d+)?%/]
          end
        else
          get "/courses/#{@course.id}/gradebook/"
          wait_for_ajaximations
          totals = ff(".canvas_1 .slick-row .slick-cell:last-child").map(& :text)
        end

        expect(totals).to eq(["83.33%", "100%"]).or eq ["83.3%", "100%"]
      end
    end

    it "formats excused grade like dropped assignment", priority: "1" do
      assignment = @course.assignments.create! title: "Excuse Me", points_possible: 20

      if view == "srgb"
        skip "Skipped because this spec fails if not run in foreground\n" \
             "This is believed to be the issue: https://code.google.com/p/selenium/issues/detail?id=7346"
        get "/courses/#{@course.id}/gradebook/change_gradebook_version?version=srgb"
        click_option f("#assignment_select"), assignment.title
        click_option f("#student_select"), @student.name
        replace_content f("#student_and_assignment_grade"), "EX", tab_out: true
        wait_for_ajaximations
      else
        assignment.grade_student(@student, excuse: true, grader: @teacher)
      end

      user_session(@student)
      get "/courses/#{@course.id}/grades"

      grade_row = f("#submission_#{assignment.id}")
      grade_cell = f(".assignment_score .grade", grade_row)
      grade = grade_cell.text.scan(/\d+|EX/).first

      expect(grade_row).to have_class ".excused"
      expect(grade).to eq "EX"
      expect(grade_row).to have_attribute("title", "This assignment is excused " \
                                                   "and will not be considered in the total calculation")
    end

    %w[percent letter_grade gpa_scale points].each do |type|
      it "is not included in grade calculations with type '#{type}'", priority: "1" do
        a1 = @course.assignments.create! title: "Excuse Me", grading_type: type, points_possible: 20
        a2 = @course.assignments.create! title: "Don't Excuse Me", grading_type: type, points_possible: 20

        if type == "points"
          a1.grade_student(@student, grade: 13.2, grader: @teacher)
          a2.grade_student(@student, grade: 20, grader: @teacher)
        else
          a1.grade_student(@student, grade: "66%", grader: @teacher)
          a2.grade_student(@student, grade: "100%", grader: @teacher)
        end

        total = ""
        if view == "srgb"
          skip "Skipped because this spec fails if not run in foreground\n" \
               "This is believed to be the issue: https://code.google.com/p/selenium/issues/detail?id=7346"
          get "/courses/#{@course.id}/gradebook/change_gradebook_version?version=srgb"
          click_option f("#student_select"), @student.name
          total = f("span.total-grade").text[/\d+(\.\d+)?%/]
          expect(total).to eq "83%"

          click_option f("#assignment_select"), a1.title
          replace_content f("#student_and_assignment_grade"), "EX", tab_out: true
          wait_for_ajaximations
          total = f("span.total-grade").text[/\d+(\.\d+)?%/]
        else
          get "/courses/#{@course.id}/gradebook/"

          total = Gradebook::Cells.get_total_grade(@course.students[0])
          expect(total).to eq "83%"

          Gradebook::Cells.edit_grade(@course.students[0], a1, "EX")
          wait_for_ajaximations
          total = Gradebook::Cells.get_total_grade(@course.students[0])
        end
        expect(total).to eq "100%"
      end
    end
  end

  context "Gradebook Grid" do
    it_behaves_like "Basic Behavior"

    it "default grade cannot be set to excused", priority: "1" do
      assignment = @course.assignments.create! title: "Test Me!", points_possible: 20
      get "/courses/#{@course.id}/grades"
      Gradebook.click_assignment_header_menu_element(assignment.id, "set default grade")

      %w[EX eX Ex ex].each_with_index do |ex, i|
        replace_content f("#student_grading_#{assignment.id}"), ex, press_return: true
        wait_for_ajaximations
        expect(ff(".ic-flash-error").length).to be i + 1
        expect(f(".ic-flash-error").text).to include "Default grade cannot be set to EX"
      end
    end

    %w[EX ex Ex eX].each do |ex|
      it "'#{ex}' can be used to excuse assignments", priority: "1" do
        assignment = @course.assignments.create! title: "Excuse Me", points_possible: 20

        get "/courses/#{@course.id}/gradebook/"

        Gradebook::Cells.edit_grade(@course.students[0], assignment, ex)
        expect { Gradebook::Cells.get_grade(@course.students[0], assignment) }.to become "Excused"
      end
    end
  end

  context "Individual View" do
    it_behaves_like "Basic Behavior", "srgb"
  end
end
