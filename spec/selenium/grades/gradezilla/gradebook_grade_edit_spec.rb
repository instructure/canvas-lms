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
# with this program. If not, see <http://www.gnu.org/licenses/>
#

require_relative '../../helpers/gradezilla_common'
require_relative '../pages/gradezilla_cells_page'
require_relative '../pages/gradezilla_page'
require_relative '../pages/grading_curve_page'
require_relative '../setup/gradebook_setup'

describe "Gradezilla editing grades" do
  include_context "in-process server selenium tests"
  include GradezillaCommon
  include GradebookSetup

  before(:once) do
    gradebook_data_setup
    show_sections_filter(@teacher)
  end

  before(:each) do
    user_session(@teacher)
  end

  after(:each) do
    clear_local_storage
  end

  it "updates a graded quiz and have the points carry over to the quiz attempts page", priority: "1", test_id: 220310 do
    points = 50
    q = factory_with_protected_attributes(@course.quizzes, :title => "new quiz", :points_possible => points, :quiz_type => 'assignment', :workflow_state => 'available')
    q.save!
    qs = q.generate_submission(@student_1)
    Quizzes::SubmissionGrader.new(qs).grade_submission
    q.reload

    Gradezilla.visit(@course)
    edit_grade('#gradebook_grid .container_1 .slick-row:nth-child(1) .b4', points.to_s)

    get "/courses/#{@course.id}/quizzes/#{q.id}/history?quiz_submission_id=#{qs.id}"
    expect(f('.score_value')).to include_text points.to_s
    expect(f('#after_fudge_points_total')).to include_text points.to_s
  end

  it "validates initial grade totals are correct", priority: "1", test_id: 220311 do
    Gradezilla.visit(@course)

    expect(final_score_for_row(0)).to eq @student_1_total_ignoring_ungraded
    expect(final_score_for_row(1)).to eq @student_2_total_ignoring_ungraded
  end

  it "changes grades and validate course total is correct", priority: "1", test_id: 220312 do
    expected_edited_total = "33.33%"
    Gradezilla.visit(@course)

    # editing grade for first row, first cell
    edit_grade('#gradebook_grid .container_1 .slick-row:nth-child(1) .b1', 0)

    # editing grade for second row, first cell
    edit_grade('#gradebook_grid .container_1 .slick-row:nth-child(2) .b1', 0)

    # refresh page and make sure the grade sticks
    Gradezilla.visit(@course)
    expect(final_score_for_row(0)).to eq expected_edited_total
    expect(final_score_for_row(1)).to eq expected_edited_total
  end

  it "allows setting a letter grade on a no-points assignment", priority: "1", test_id: 220313 do
    assignment_model(course: @course, grading_type: 'letter_grade', points_possible: nil, title: 'no-points')
    Gradezilla.visit(@course)

    edit_grade('#gradebook_grid .container_1 .slick-row:nth-child(1) .b4', 'A-')

    expect(f('#gradebook_grid .container_1 .slick-row:nth-child(1) .b4')).to include_text('A-')
    expect(@assignment.submissions.where('grade is not null').count).to eq 1

    sub = @assignment.submissions.where('grade is not null').first

    expect(sub.grade).to eq 'A-'
    expect(sub.score).to eq 0.0
  end

  it "does not update default grades for users not in this section", priority: "1", test_id: 220314 do
    # create new user and section

    Gradezilla.visit(@course)
    switch_to_section(@other_section)

    Gradezilla.click_assignment_header_menu(@third_assignment.id)
    set_default_grade(2, 13)
    @other_section.users.each { |u| expect(u.submissions.map(&:grade)).to include '13' }
    @course.default_section.users.each { |u| expect(u.submissions.map(&:grade)).not_to include '13' }
  end

  it "tab sets focus on the options menu trigger when editing a grade", priority: "1" do
    Gradezilla.visit(@course)

    first_cell = Gradezilla::Cells.grading_cell(@student_1, @second_assignment)
    first_cell.click
    grade_input = Gradezilla::Cells.grading_cell_input(@student_1, @second_assignment)
    set_value(grade_input, 3)
    grade_input.send_keys(:tab)
    expect(first_cell).to have_class('editable')
  end

  it "'tabs' forward out of the grid when focused on the options menu", priority: "1", test_id: 3455461 do
    Gradezilla.visit(@course)

    first_cell = Gradezilla::Cells.grading_cell(@student_1, @second_assignment)
    first_cell.click

    # Tab to the options menu, then again to leave the cell
    driver.action.send_keys(:tab).perform
    driver.action.send_keys(:tab).perform

    next_cell = f('#gradebook_grid .container_1 .slick-row:nth-child(1) .b3')
    expect(next_cell).not_to have_class('editable')
  end

  it "'shift-tab' within the grid navigates backward out of the grid", priority: "1", test_id: 3455462 do
    Gradezilla.visit(@course)

    second_cell = Gradezilla::Cells.grading_cell(@student_1, @second_assignment)
    second_cell.click
    grade_input = Gradezilla::Cells.grading_cell_input(@student_1, @second_assignment)
    grade_input.send_keys(%i[shift tab])

    first_cell = Gradezilla::Cells.grading_cell(@student_1, @first_assignment)
    expect(first_cell).not_to have_class('editable')
  end

  it "'tab' into the grid activates the first header cell by default", priority: "1", test_id: 3455459 do
    Gradezilla.visit(@course)

    # Select the search field (the closest element we can "click" that won't
    # cause something else to pop up), then tab to the settings icon and from
    # there to the grid itself (which requires two tabs to enter).
    f('.search-query').click
    3.times { driver.action.send_keys(:tab).perform }

    first_header_cell = Gradezilla.slick_headers_selector.first
    expect(first_header_cell).to contain_css(':focus')
  end

  it "'tab' into the grid re-activates the previously-active cell if set", priority: "1", test_id: 3455460 do
    Gradezilla.visit(@course)

    selected_cell = Gradezilla::Cells.grading_cell(@student_1, @second_assignment)
    selected_cell.click

    driver.action.send_keys(%i[shift tab]).perform
    driver.action.send_keys(:tab).perform
    driver.action.send_keys(:tab).perform

    expect(selected_cell).to have_class('editable')
  end

  it "displays dropped grades correctly after editing a grade", priority: "1", test_id: 220316 do
    @course.assignment_groups.first.update!(rules: 'drop_lowest:1')
    Gradezilla.visit(@course)

    expect(Gradezilla::Cells.grading_cell(@student_1, @second_assignment)).to contain_css('.dropped')
    a3 = Gradezilla::Cells.grading_cell(@student_1, @third_assignment)
    expect(a3).not_to contain_css('.dropped')

    a3.click
    grade_input = Gradezilla::Cells.grading_cell_input(@student_1, @third_assignment)
    set_value(grade_input, 3)
    grade_input.send_keys(:arrow_right)
    # the third assignment now has the lowest score and is dropped
    expect(Gradezilla::Cells.grading_cell(@student_1, @second_assignment)).not_to contain_css('.dropped')
    expect(Gradezilla::Cells.grading_cell(@student_1, @third_assignment)).to contain_css('.dropped')
  end

  it "updates a grade when clicking outside of slickgrid", priority: "1", test_id: 220319 do
    Gradezilla.visit(@course)

    first_cell = Gradezilla::Cells.grading_cell(@student_1, @second_assignment)
    first_cell.click
    grade_input = Gradezilla::Cells.grading_cell_input(@student_1, @second_assignment)
    set_value(grade_input, 3)
    f('body').click
    expect(f("body")).not_to contain_css('.gradebook_cell_editable')
  end

  it "validates curving grades option", priority: "1", test_id: 220320 do
    skip_if_chrome('issue with set_value')
    skip_if_safari(:alert)
    curved_grade_text = "8"

    Gradezilla.visit(@course)
    Gradezilla.click_assignment_header_menu_element(@first_assignment.id,"curve grades")
    curve_form = GradingCurvePage.new
    curve_form.edit_grade_curve(curved_grade_text)
    curve_form.curve_grade_submit
    accept_alert

    expect(find_slick_cells(1, f('#gradebook_grid .container_1'))[0]).to include_text curved_grade_text
  end

  it "assigns zeroes to unsubmitted assignments during curving", priority: "1", test_id: 220321 do
    skip_if_safari(:alert)
    @first_assignment.grade_student(@student_2, grade: '', grader: @teacher)
    Gradezilla.visit(@course)
    Gradezilla.click_assignment_header_menu_element(@first_assignment.id,"curve grades")

    f('#assign_blanks').click
    fj('.ui-dialog-buttonpane button:visible').click
    accept_alert

    expect(find_slick_cells(1, f('#gradebook_grid .container_1'))[0]).to include_text '0'
  end

  it "does not factor non graded assignments into group total", priority: "1", test_id: 220323 do
    expected_totals = [@student_1_total_ignoring_ungraded, @student_2_total_ignoring_ungraded]
    ungraded_submission = @ungraded_assignment.submit_homework(@student_1, :body => 'student 1 submission ungraded assignment')
    @ungraded_assignment.grade_student(@student_1, grade: 20, grader: @teacher)
    ungraded_submission.save!
    Gradezilla.visit(@course)
    assignment_group_cells = ff('.assignment-group-cell')
    expected_totals.zip(assignment_group_cells) do |expected, cell|
      expect(cell).to include_text expected
    end
  end

  it "validates setting default grade for an assignment", priority: "1", test_id: 220383 do
    expected_grade = "45"
    Gradezilla.visit(@course)
    Gradezilla.click_assignment_header_menu(@third_assignment.id)
    set_default_grade(2, expected_grade)
    grade_grid = f('#gradebook_grid .container_1')
    StudentEnrollment.count.times do |n|
      expect(find_slick_cells(n, grade_grid)[2]).to include_text expected_grade
    end
  end

  context 'with an invalid grade' do
    before :once do
      init_course_with_students 1
      @assignment = @course.assignments.create!(grading_type: 'points', points_possible: 10)
      @assignment.grade_student(@students[0], grade: 10, grader: @teacher)
    end

    before :each do
      user_session(@teacher)
      Gradezilla.visit(@course)
    end

    it 'indicates an error without posting the grade', priority: "1", test_id: 3455458 do
      Gradezilla::Cells.edit_grade(@students[0], @assignment, 'invalid')
      current_cell = Gradezilla::Cells.grading_cell(@students[0], @assignment)
      expect(current_cell).to contain_css(".Grid__AssignmentRowCell__InvalidGrade")
      refresh_page
      current_score = Gradezilla::Cells.get_grade(@students[0], @assignment)
      expect(current_score).to eq('10')
    end
  end

  context 'with grading periods' do
    before(:once) do
      root_account = @course.root_account = Account.default

      group = Factories::GradingPeriodGroupHelper.new.create_for_account(root_account)
      group.enrollment_terms << @course.enrollment_term
      group.save!

      period_helper = Factories::GradingPeriodHelper.new
      @first_period = period_helper.create_presets_for_group(group, :past).first
      @first_period.save!
      @second_period = period_helper.create_presets_for_group(group, :current).first
      @second_period.save!

      @first_assignment.due_at = @first_period.close_date - 1.day
      @first_assignment.save!
      @first_assignment.reload

      @second_assignment.due_at = @second_period.close_date - 1.day
      @second_assignment.save!
      @second_assignment.reload
    end

    context 'for assignments with at least one due date in a closed grading period' do
      before(:each) do
        show_grading_periods_filter(@teacher)
        Gradezilla.visit(@course)
        Gradezilla.select_grading_period('All Grading Periods')
        Gradezilla.click_assignment_header_menu(@first_assignment.id)
      end

      describe 'the Curve Grades menu item' do
        before(:each) do
          @curve_grades_menu_item = Gradezilla.assignment_header_menu_item_selector('Curve Grades')
        end

        # TODO: refactor and add back when InstUI changes are applied
        # it 'is disabled' do
        #   expect(@curve_grades_menu_item[:class]).to include('ui-state-disabled')
        # end

        it 'gives an error when clicked' do
          @curve_grades_menu_item.click

          expect_flash_message :error, "Unable to curve grades"
        end
      end

      describe 'the Set Default Grade menu item' do
        before(:each) do
          @set_default_grade_menu_item = Gradezilla.assignment_header_menu_item_selector('Set Default Grade')
        end

        # TODO: refactor and add back when InstUI changes are applied
        # it 'is disabled' do
        #   expect(@set_default_grade_menu_item[:class]).to include('[ui-state-disabled]')
        # end

        it 'gives an error when clicked' do
          @set_default_grade_menu_item.click

          expect_flash_message :error, "Unable to set default grade"
        end
      end
    end
  end
end
