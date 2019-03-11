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

require_relative "../../common"
require_relative "../pages/speedgrader_page"
require_relative '../pages/student_grades_page'

describe 'SpeedGrader Post Policy' do
  include_context "in-process server selenium tests"

  before :once do
    skip('Unskip in GRADE-1943')
    # course
    course_with_teacher(
      course_name: "Post Policy Course",
      active_course: true,
      active_enrollment: true,
      name: "Teacher Boss1",
      active_user: true
    )
    @course.enable_feature!(:new_gradebook)
    # TODO: set post policy course setting to manual

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
    Speedgrader.visit(@course.id, @assignment.id)
  end

  context do
    before :once do
      @students.each do |student|
        @assignment.grade_student(student, grade: 8, grader: @teacher)
        @ssignment.update_submission(
          student,
          author: @teacher,
          comment: 'Teacher Commented'
        )
      end
    end

    context 'when post everyone' do
      before :each do
        skip('Unskip in GRADE-1943')
        manually_post_grades('Everyone')
      end

      it 'post grades option disabled' do
        skip('Unskip in GRADE-1943')
        # TODO: expect post option to be disabled for Speedgrader.post_grades
      end

      it 'students see grade', priority: '1', test_id: 3757534 do
        @students.each do |student|
          verify_student_grade_comments_displayed(student, '8')
        end
      end
    end

    context 'when post everyone for section' do
      before :each do
        skip('Unskip in GRADE-1943')
        manually_post_grades('Everyone', @section2)
      end

      it 'posts for section', priority: '1', test_id: 3757535 do
        @students1.each do |student|
          verify_student_grade_comments_displayed(student, '8')
        end
      end

      it 'does not post for other section', priority: '1', test_id: 3757535 do
        skip('Unskip in GRADE-1943')
        expect(Speedgrader.hidden_pill).to be_displayed

        # TODO: verify students not in section have eyeball icon
        @students2.each do |student|
          verify_student_grade_comments_displayed(student, '')
          # TODO: expect eyeball icon to be displayed
        end
      end

      it 'Post tray shows unposted count', priority: '1', test_id: 3757535 do
        skip('Unskip in GRADE-1943')
        expect(Speedgrader.PostGradesTray.unposted_count).to eq '2'
        # TODO: expect unposted indicator to be displayed and show count 2
      end
    end

    context 'when hide posted grades for everyone' do
      before :each do
        skip('Unskip in GRADE-1943')
        manually_post_grades('Everyone')
        wait_for_ajaximations
        Speedgrader.visit(@course.id, @assignment.id)
        manually_hide_grades
        wait_for_ajaximations
      end

      it 'header has HIDDEN icon', priority: '1', test_id: 3757537 do
        skip('Unskip in GRADE-1943')
        # TODO: expect header to have HIDDEN icon Speedgrader.grades_not_posted_icon
      end

      it 'student sees hidden icon', priority: '1', test_id: 3757537 do
        @students.each do |student|
          verify_student_grade_displayed(student, '')
          # TODO: expect hidden icon to be displayed
        end
      end

      it 'hidden pill displayed in side panel', priority: '1', test_id: 3757537 do
        skip('Unskip in GRADE-1943')
        expect(Speedgrader.hidden_pill).to be_displayed
      end
    end

    context 'when hide posted grades for section' do
      before :each do
        skip('Unskip in GRADE-1943')
        manually_post_grades('Everyone')
        wait_for_ajaximations
        manually_hide_grades(@section2)
        wait_for_ajaximations
      end

      it 'students in section have hidden grades', priority: '1', test_id: 3756683 do
        skip('Unskip in GRADE-1943')
        @students1.each do |student|
          verify_student_grade_comments_displayed(student, '')
          # TODO: expect hidden icon to be displayed
        end
      end

      it 'students in another section have grades posted', priority: '1', test_id: 3756683 do
        @students2.each do |student|
          verify_student_grade_comments_displayed(student, '8')
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
      skip('Unskip in GRADE-1943')
      manually_post_grades('Graded')
    end

    it 'posts for graded', priority: '1', test_id: 3756680 do
      @graded_students.each do |student|
        verify_student_grade_comments_displayed(student, 8)
      end
    end

    it 'does not post for ungraded', priority: '1', test_id: 3756680 do
      skip('Unskip in GRADE-1943')
      # TODO: verify ungraded students still have eyeball icon
      verify_student_grade_comments_displayed(@students[3], '')
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
      skip('Unskip in GRADE-1943')
      manually_post_grades('Graded', @section2)
    end

    it 'posts graded for section', priority: '1', test_id: 3757539 do
      verify_student_grade_comments_displayed(@students2.first, '8')
    end

    it 'does not post ungraded for section', priority: '1', test_id: 3757539 do
      skip('Unskip in GRADE-1943')
      # TODO: verify students in section without grades have eyeball icon
      verify_student_grade_comments_displayed(@students2.second, '')
      # TODO: expect eyeball icon to be displayed
    end

    it 'does not post graded for other section', priority: '1', test_id: 3757539 do
      @students1.each do |student|
        verify_student_grade_comments_displayed(student, '')
      end
    end
  end

  def verify_student_grade_comments_displayed(student, grade)
    user_session(student)
    StudentGradesPage.visit_as_student(@course)
    expect(StudentGradesPage.fetch_assignment_score(@assignment)).to eq grade
    expect(StudentGradesPage.comments(@assignment).first).to include_text 'Teacher Commented' unless grade.eql? ''
  end

  def manually_post_grades(type, section = nil)
    Speedgrader.click_post_link
    Speedgrader.PostGradesTray.post_type_radio_button(type).click
    Speedgrader.PostGradesTray.select_section(section.name) unless section.nil?
    Speedgrader.PostGradesTray.post_button.click
  end

  def manually_hide_grades(section = nil)
    Speedgrader.click_hide_link
    Speedgrader.HideGradesTray.select_section(section.name) unless section.nil?
    Speedgrader.HideGradesTray.hide_button.click
  end
end
