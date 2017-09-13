#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative '../../../common'
require_relative '../../../helpers/assignments_common'
require_relative '../../pages/gradezilla_page'

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
      enable_all_rcs @course.account
      stub_rcs_config
      assignment_2
      user_session(teacher)
      get "/courses/#{test_course.id}/assignments/#{assignment_2.id}/edit"
    end

    it 'do not count towards final grade checkbox is visible on edit' do
      expect(omit_from_final_checkbox).to be_present
    end
  end
end
