#
# Copyright (C) 2016 - present Instructure, Inc.
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
require_relative '../../helpers/assignments_common'
require_relative '../pages/gradezilla_page'

describe 'Gradezilla omit from final grade assignments' do
  include_context "in-process server selenium tests"
  include AssignmentsCommon

  let(:test_course) { course_factory(active_course: true) }
  let(:teacher)     { user_factory(active_all: true) }
  let(:student)     { user_factory(active_all: true) }
  let(:enroll_teacher_and_students) do
    test_course.enroll_user(teacher, 'TeacherEnrollment', enrollment_state: 'active')
    test_course.enroll_user(student, 'StudentEnrollment', enrollment_state: 'active')
  end
  let(:assignment_1) do
    test_course.assignments.create!(
      title: 'Points Assignment',
      grading_type: 'points',
      points_possible: 10,
      submission_types: 'online_text_entry'
    )
  end
  let(:assignment_2) do
    test_course.assignments.create!(
      title: 'Assignment not counted towards final grade',
      grading_type: 'points',
      points_possible: 10
    )
  end
  let(:assignment_3) do
    test_course.assignments.create!(
      title: 'Also not for final grade',
      grading_type: 'points',
      points_possible: 10,
      omit_from_final_grade: true
    )
  end
  let(:omit_from_final_checkbox) { f('#assignment_omit_from_final_grade') }

  context 'assignment edit and show pages' do
    before(:each) do
      enroll_teacher_and_students
      assignment_2
      user_session(teacher)
      get "/courses/#{test_course.id}/assignments/#{assignment_2.id}/edit"
    end

    it 'do not count towards final grade checkbox is visible on edit' do
      expect(omit_from_final_checkbox).to be_present
    end

    it 'saves setting with warning on assignment show page' do
      expect(f('#content')).not_to contain_jqcss('.omit-from-final-warning:visible')

      omit_from_final_checkbox.click
      submit_assignment_form

      expect(f('.omit-from-final-warning')).to include_text('This assignment does not count toward the final grade.')
    end
  end

  context 'as a student' do
    before(:each) do
      enroll_teacher_and_students
      assignment_1.grade_student(student, grade: 10, grader: teacher)
      assignment_3.grade_student(student, grade: 5, grader: teacher)
      user_session(student)
      get "/courses/#{test_course.id}/grades"
    end

    it 'displays warning in the student grades page' do
      f('.icon-warning').click

      expect(f("#final_grade_info_#{assignment_3.id} th")).to include_text('Final Grade Info')
    end

    it 'displays correct total on student grades page' do
      expect(f('#submission_final-grade .grade')).to include_text('100%')
    end
  end
end
