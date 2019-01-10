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

require File.expand_path(File.dirname(__FILE__) + '/../common')

module GradezillaCommon
  def init_course_with_students(num = 1)
    course_with_teacher(active_all: true)

    @students = []
    (1..num).each do |i|
      student = User.create!(:name => "Student_#{i} lastname#{i}")
      student.register!

      e1 = @course.enroll_student(student)
      e1.workflow_state = 'active'
      e1.save!
      @course.reload

      @students.push student
    end
  end

  def set_default_grade(cell_index, points = "5")
    move_to_click('[data-menu-item-id="set-default-grade"]')
    dialog = find_with_jquery('.ui-dialog:visible')
    f('.grading_value').send_keys(points)
    submit_dialog(dialog, '.ui-button')
    accept_alert
  end

  def find_slick_cells(row_index, element)
    grid = element
    rows = grid.find_elements(:css, '.slick-row')
    ff('.slick-cell', rows[row_index])
  end

  def edit_grade(cell, grade)
    fj(cell).click
    grade_input = fj("#{cell} input[type='text']")
    set_value(grade_input, grade)
    grade_input.send_keys(:return)
    wait_for_ajaximations
  end

  def open_comment_dialog(x=0, y=0)
    cell = f("#gradebook_grid .container_1 .slick-row:nth-child(#{y+1}) .slick-cell:nth-child(#{x+1})")
    cell.click
    fj('.Grid__AssignmentRowCell__Options button:visible', cell).click
    f('#ShowSubmissionDetailsAction').click
    # the dialog fetches the comments async after it displays and then innerHTMLs the whole
    # thing again once it has fetched them from the server, completely replacing it
    wait_for_ajax_requests
    fj('.submission_details_dialog:visible')
  end

  def final_score_for_row(row)
    grade_grid = f('#gradebook_grid .container_1')
    cells = find_slick_cells(row, grade_grid)
    cells[4].find_element(:css, '.percentage').text
  end

  def switch_to_section(section=nil)
    ::Gradezilla.select_section(section)
  end

  def gradebook_data_setup(opts={})
    assignment_setup_defaults
    assignment_setup(opts)
  end

  def assignment_setup_defaults
    @assignment_1_points = "10"
    @assignment_2_points = "5"
    @assignment_3_points = "50"
    @attendance_points = "15"

    @student_name_1 = "student1 last1"
    @student_name_2 = "student2 last2"
    @student_name_3 = "student3 last3"

    @student_1_total_ignoring_ungraded = "100%"
    @student_2_total_ignoring_ungraded = "66.67%"
    @student_3_total_ignoring_ungraded = "66.67%"
    @student_1_total_treating_ungraded_as_zeros = "18.75%"
    @student_2_total_treating_ungraded_as_zeros = "12.5%"
    @student_3_total_treating_ungraded_as_zeros = "12.5%"
    @default_password = "qwertyuiop"
  end

  def assignment_setup(opts={})
    course_with_teacher({active_all: true}.merge(opts))
    @course.grading_standard_enabled = true
    @course.save!
    @course.reload

    # add first student
    @student_1 = User.create!(:name => @student_name_1)
    @student_1.register!
    @student_1.pseudonyms.create!(:unique_id => "nobody1@example.com", :password => @default_password, :password_confirmation => @default_password)

    e1 = @course.enroll_student(@student_1)
    e1.workflow_state = 'active'
    e1.save!
    @course.reload

    # add second student
    @other_section = @course.course_sections.create(:name => "the other section")
    @student_2 = User.create!(:name => @student_name_2)
    @student_2.register!
    @student_2.pseudonyms.create!(:unique_id => "nobody2@example.com", :password => @default_password, :password_confirmation => @default_password)
    e2 = @course.enroll_student(@student_2, :section => @other_section)

    e2.workflow_state = 'active'
    e2.save!
    @course.reload

    # add third student
    @student_3 = User.create!(:name => @student_name_3)
    @student_3.register!
    @student_3.pseudonyms.create!(:unique_id => "nobody3@example.com", :password => @default_password, :password_confirmation => @default_password)
    e3 = @course.enroll_student(@student_3)
    e3.workflow_state = 'active'
    e3.save!
    @course.reload

    @all_students = [@student_1, @student_2, @student_3]

    # first assignment data
    @group = @course.assignment_groups.create!(:name => 'first assignment group', :group_weight => 100)
    @first_assignment = assignment_model({
                                           :course => @course,
                                           :name => 'A name that would not reasonably fit in the header cell which should have some limit set',
                                           :due_at => nil,
                                           :points_possible => @assignment_1_points,
                                           :submission_types => 'online_text_entry,online_upload',
                                           :assignment_group => @group
                                         })
    rubric_model
    @association = @rubric.associate_with(@assignment, @course, :purpose => 'grading')
    @assignment.reload
    @assignment.submit_homework(@student_1, :body => 'student 1 submission assignment 1')
    @assignment.grade_student(@student_1, grade: 10, grader: @teacher)

    # second student submission for assignment 1
    @assignment.submit_homework(@student_2, :body => 'student 2 submission assignment 1')
    @assignment.grade_student(@student_2, grade: 5, grader: @teacher)

    # third student submission for assignment 1
    @student_3_submission = @assignment.submit_homework(@student_3, :body => 'student 3 submission assignment 1')
    @assignment.grade_student(@student_3, grade: 5, grader: @teacher)

    # second assignment data
    @second_assignment = assignment_model({
                                            :course => @course,
                                            :name => 'second assignment',
                                            :due_at => nil,
                                            :points_possible => @assignment_2_points,
                                            :submission_types => 'online_text_entry',
                                            :assignment_group => @group
                                          })
    @second_association = @rubric.associate_with(@second_assignment, @course, :purpose => 'grading')

    # all students get a 5 on assignment 2
    @all_students.each do |s|
      @second_assignment.submit_homework(s, :body => "#{s.name} submission assignment 2")
      @second_assignment.grade_student(s, grade: 5, grader: @teacher)
    end

    # third assignment data
    due_date = Time.zone.now + 1.day
    @third_assignment = assignment_model({
                                           :course => @course,
                                           :name => 'assignment three',
                                           :due_at => due_date,
                                           :points_possible => @assignment_3_points,
                                           :submission_types => 'online_text_entry',
                                           :assignment_group => @group
                                         })
    @third_association = @rubric.associate_with(@third_assignment, @course, :purpose => 'grading')

    # attendance assignment
    @attendance_assignment = assignment_model({
                                                :course => @course,
                                                :name => 'attendance assignment',
                                                :title => 'attendance assignment',
                                                :due_at => nil,
                                                :points_possible => @attendance_points,
                                                :submission_types => 'attendance',
                                                :assignment_group => @group,
                                              })

    @ungraded_assignment = @course.assignments.create!(
      :title => 'not-graded assignment',
      :submission_types => 'not_graded',
      :assignment_group => @group
    )
  end

  shared_context 'late_policy_course_setup' do
    let(:now) { Time.zone.now }

    def create_course_late_policy
      # create late/missing policies on backend
      @course.create_late_policy!(
        missing_submission_deduction_enabled: true,
        missing_submission_deduction: 50.0,
        late_submission_deduction_enabled: true,
        late_submission_deduction: 10.0,
        late_submission_interval: 'day',
        late_submission_minimum_percent_enabled: true,
        late_submission_minimum_percent: 50.0,
      )
    end

    def create_assignments
      # create 2 assignments due in the past
      @a1 = @course.assignments.create!(
        title: 'assignment one',
        grading_type: 'points',
        points_possible: 100,
        due_at: 1.day.ago(now),
        submission_types: 'online_text_entry'
      )

      @a2 = @course.assignments.create!(
        title: 'assignment two',
        grading_type: 'points',
        points_possible: 100,
        due_at: 1.day.ago(now),
        submission_types: 'online_text_entry'
      )

      # create 1 assignment due in the future
      @a3 = @course.assignments.create!(
        title: 'assignment three',
        grading_type: 'points',
        points_possible: 10,
        due_at: 2.days.from_now,
        submission_types: 'online_text_entry'
      )

      # create 1 assignment that will be Excused for Student1
      @a4 = @course.assignments.create!(
        title: 'assignment four',
        grading_type: 'points',
        points_possible: 10,
        due_at: 2.days.from_now,
        submission_types: 'online_text_entry'
      )
    end

    def make_submissions
      # submit a1(late) and a3(on-time) so a2(missing)
      Timecop.freeze(now) do
        @a1.submit_homework(@course.students.first, body: 'submitting my homework')
        @a3.submit_homework(@course.students.first, body: 'submitting my homework')
      end
    end

    def grade_assignments
      # as a teacher grade the assignments
      @a1.grade_student(@course.students.first, grade: 90, grader: @teacher)
      @a2.grade_student(@course.students.first, grade: 90, grader: @teacher)
      @a3.grade_student(@course.students.first, grade: 9, grader: @teacher)
      @a4.grade_student(@course.students.first, excuse: true, grader: @teacher)
    end
  end
end

