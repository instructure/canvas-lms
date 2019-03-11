#
# Copyright (C) 2019 - present Instructure, Inc.
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

require_relative '../../common'
require_relative '../pages/gradezilla_page'
require_relative '../pages/gradezilla/settings'
require_relative '../pages/student_grades_page'
require_relative '../pages/gradezilla_cells_page'

describe 'Gradezilla Post Policy' do
  include_context "in-process server selenium tests"

  before :once do
    preload_graphql_schema
    # course
    course_with_teacher(
      course_name: "Post Policy Course",
      active_course: true,
      active_enrollment: true,
      name: "Teacher Boss1",
      active_user: true
    )
    @course.enable_feature!(:new_gradebook)
    @course.enable_feature!(:post_policies)
    @course.post_policies.create!(post_manually: true)

    # sections
    @section1 = @course.course_sections.first
    @section2 = @course.course_sections.create!(:name => 'Section 2')
    # students
    @students1 = create_users_in_course(@course, 2, return_type: :record, name_prefix: "Purple", section: @section1)
    @students2 = create_users_in_course(@course, 2, return_type: :record, name_prefix: "Indigo", section: @section2)
    @students = @students1.concat(@students2)
    # assignment
    @assignment = @course.assignments.create!(
      title: 'post policy assignment',
      submission_types: 'online_text_entry',
      grading_type: 'points',
      points_possible: 10
    )
  end

  before :each do
    user_session(@teacher)
    Gradezilla.visit(@course)
  end

  context do
    before :once do
      @students.each do |student|
        @assignment.grade_student(student, grade: 8, grader: @teacher)
      end
    end

    context 'when post everyone' do
      before :each do
        skip('Unskip in GRADE-63')
        manually_post_grades('Everyone')
      end

      it 'post grades option disabled' do
        skip('Unskip in GRADE-63')
        GradezillaPage.click_assignment_header_menu(@assignment)
        # TODO: expect post option to be disabled
      end

      it 'students see grade', priority: '1', test_id: 3756679 do
        @students.each do |student|
          verify_student_grade_displayed(student, '8')
        end
      end
    end

    context 'when post everyone for section' do
      before :each do
        skip('Unskip in GRADE-63')
        manually_post_grades('Everyone', @section2)
      end

      it 'posts for section', priority: '1', test_id: 3756681 do
        @students1.each do |student|
          verify_student_grade_displayed(student, '8')
        end
      end

      it 'does not post for other section', priority: '1', test_id: 3756681 do
        skip('Unskip in ticket to be created for student grades page')
        # open submission tray, check for pill
        Gradezilla::Cells.open_tray(@students2.first, @assignment)
        expect(Gradezilla::GradeDetailTray.not_posted_pill).to be_displayed

        # TODO: verify students not in section have eyeball icon
        @students2.each do |student|
          verify_student_grade_displayed(student, '')
          # TODO: expect eyeball icon to be displayed
        end
      end

      it 'Post tray shows unposted count', priority: '1', test_id: 3756684 do
        skip('Unskip in GRADE-63')
        Gradezilla.click_post_grades(@assignment.id)
        # TODO: expect unposted indicator to be displayed and show count 2
      end
    end

    context 'when hide posted grades for everyone' do
      before :each do
        skip('Unskip in GRADE-1938')
        manually_post_grades('Everyone')
        wait_for_ajaximations
        Gradezilla.click_hide_grades(@assignment.id)
        Gradezilla::HideGradesTray.hide_button.click
        wait_for_ajaximations
      end

      it 'header has HIDDEN', priority: '1', test_id: 3756682 do
        skip('Unskip in GRADE-1938')
        # TODO: expect header to have HIDDEN
      end

      it 'student sees hidden icon', priority: '1', test_id: 3756682 do
        @students.each do |student|
          verify_student_grade_displayed(student, '')
          # TODO: expect hidden icon to be displayed
        end
      end

      it 'hidden pill displayed in submission tray', priority: '1', test_id: 3756682 do
        skip('Unskip in GRADE-1938')
        Gradezilla::Cells.open_tray(@students2.first, @assignment)
        expect(Gradezilla::GradeDetailTray.hidden_pill).to be_displayed
      end
    end

    context 'when hide posted grades for section' do
      before :each do
        skip('Unskip in GRADE-1938')
        manually_post_grades('Everyone')
        wait_for_ajaximations
        Gradezilla.click_hide_grades(@assignment.id)
        Gradezilla::HideGradesTray.select_section(@section2)
        Gradezilla::HideGradesTray.hide_button.click
        wait_for_ajaximations
      end

      it 'students in section have hidden grades', priority: '1', test_id: 3756683 do
        skip('Unskip in GRADE-1938')
        @students1.each do |student|
          verify_student_grade_displayed(student, '')
          # TODO: expect hidden icon to be displayed
        end
      end

      it 'students in another section have grades posted', priority: '1', test_id: 3756683 do
        @students2.each do |student|
          verify_student_grade_displayed(student, '8')
        end
      end
    end
  end

  context 'when post for graded' do
    before :once do
      @graded_students = [@students[0], @students[1], @students[2]]
      @graded_students.each do |student|
        @assignment.grade_student(student, grade: 8, grader: @teacher)
      end
    end

    before :each do
      skip('Unskip in GRADE-63')
      manually_post_grades('Graded')
    end

    it 'posts for graded', priority: '1', test_id: 3756680 do
      @graded_students.each do |student|
        verify_student_grade_displayed(student, 8)
      end
    end

    it 'does not post for ungraded', priority: '1', test_id: 3756680 do
      skip('Unskip in ticket to be created for student grades page')
      # TODO: verify ungraded students still have eyeball icon
      verify_student_grade_displayed(@students[3], '')
      # TODO: expect icon to be displayed
    end
  end

  context 'when post graded for section' do
    before :once do
      @assignment.grade_student(@students2.first, grade: 8, grader: @teacher)
      @students1.each do |student|
        @assignment.grade_student(student, grade: 8, grader: @teacher)
      end
    end

    before :each do
      skip('Unskip in GRADE-63')
      manually_post_grades('Graded', @section2)
    end

    it 'posts graded for section', priority: '1', test_id: 3756681 do
      verify_student_grade_displayed(@students2.first, '8')
    end

    it 'does not post ungraded for section', priority: '1', test_id: 3756681 do
      skip('Unskip in ticket to be created for student grades page')
      # TODO: verify students in section without grades have eyeball icon
      verify_student_grade_displayed(@students2.second, '')
      # TODO: expect eyeball icon to be displayed
    end

    it 'does not post graded for other section', priority: '1', test_id: 3756681 do
      @students1.each do |student|
        verify_student_grade_displayed(student, '')
      end
    end
  end

  context 'when Post Policy set to Automatically' do
    before :each do
      skip('Unskip in GRADE-1995')
      Gradezilla.settings_cog_select
      Gradezilla::Settings.click_post_policy_tab
      Gradezilla::PostingPolicies.select_automatically
      Gradezilla::Settings.click_update_button
      wait_for_ajaximations

      Gradezilla::Cells.edit_grade(@students1.first, @assignment, '9')
    end

    it 'grades are posted immediately', priority: '1', test_id: 3756687 do
      verify_student_grade_displayed(@students1.first, '9')
    end
  end

  context 'assignment level post policy automatically' do
    before :each do
      skip('Unskip in GRADE-63')
      Gradezilla.click_post_grades(@assignment.id)
      Gradezilla::AssignmentPostingPolicy.post_policy_type_radio_button('Automatically').click
      Gradezilla::AssignmentPostingPolicy.save_button.click

      Gradezilla::Cells.edit_grade(@students1.first, @assignment, '9')
    end

    it 'posts grade immediately', priority: '1', test_id: 3756685 do
      verify_student_grade_displayed(@students1.first, '9')
    end
  end


  def verify_student_grade_displayed(student, grade)
    user_session(student)
    StudentGradesPage.visit_as_student(@course)
    expect(StudentGradesPage.fetch_assignment_score(@assignment)).to eq grade
  end

  def manually_post_grades(type, section = nil)
    Gradezilla.click_post_grades(@assignment.id)
    Gradezilla::PostGradesTray.post_type_radio_button(type).click
    Gradezilla::PostGradesTray.select_section(section.name) unless section.nil?
    Gradezilla::PostGradesTray.post_button.click
  end
end
