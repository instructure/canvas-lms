#
# Copyright (C) 2018 - present Instructure, Inc.
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

require_relative '../../helpers/gradebook_common'
require_relative '../pages/gradebook_page'

describe 'Original Gradebook' do
  include_context "in-process server selenium tests"
  include GradebookCommon

  before(:each) do
    Account.default.enable_feature!(:anonymous_moderated_marking)
    Account.default.enable_feature!(:anonymous_grading)

    @gradebook = Gradebook::MultipleGradingPeriods.new

    # create a course with a teacher
    @anonymous_course = create_course(course_name: 'anonymous_course', active_all: true)
    @teacher1 = User.create!(name: 'Teacher1')
    @teacher1.register!
    @anonymous_course.enroll_teacher(@teacher1, enrollment_state: 'active')

    # create an anonymous assignment
    @anonymous_assignment = @anonymous_course.assignments.create!(
      title: 'Anonymous Assignment1',
      grader_count: 1,
      grading_type: 'points',
      points_possible: 15,
      submission_types: 'online_upload',
      anonymous_grading: true
    )

    # add two students
    @student_1 = User.create!(name: 'Student M. First')
    @student_1.register!
    @student_1.pseudonyms.create!(unique_id: "nobody1@example.com",
                                  password: 'password',
                                  password_confirmation: 'password')
    student_enrollment1 = @anonymous_course.enroll_student(@student_1)
    student_enrollment1.update!(workflow_state: 'active')

    @student_2 = User.create!(name: 'Student M. Second')
    @student_2.register!
    @student_2.pseudonyms.create!(unique_id: "nobody2@example.com",
                                  password: 'password',
                                  password_confirmation: 'password')
    student_enrollment2 = @anonymous_course.enroll_student(@student_2)
    student_enrollment2.update!(workflow_state: 'active')
  end

  context 'with Anonymous Moderated Marking ON in submission detail' do
    before(:each) do
      user_session(@teacher1)
      @gradebook.visit_gradebook(@anonymous_course)
      open_comment_dialog(0,1)
    end

    it 'cannot navigate to speedgrader for specific student', priority: '1', test_id: 3493483 do
      # try to navigate to @student_2
      submission_detail_speedgrader_link.click
      driver.switch_to.window(driver.window_handles.last)
      wait_for_ajaximations
      expect(driver.current_url).not_to include "student_id"
    end
  end
end
