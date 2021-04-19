# frozen_string_literal: true

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

require_relative './page_objects/student_assignment_page_v2'
require_relative '../common'

describe 'assignments' do
  include_context "in-process server selenium tests"

  context 'as a student' do
    before(:once) do
      Account.default.enable_feature!(:assignments_2_student)
      course_with_student(course: @course, active_all: true)
      @assignment = @course.assignments.create!(
        name: 'assignment',
        due_at: 5.days.ago,
        points_possible: 10,
        submission_types: 'online_upload'
      )
    end

    before(:each) do
      user_session(@student)
      StudentAssignmentPageV2.visit(@course, @assignment)
    end

    it 'should allow you to submit a comment when there is no submission' do
      StudentAssignmentPageV2.view_feedback_button.click
      StudentAssignmentPageV2.leave_a_comment('test comment')
      expect(StudentAssignmentPageV2.comment_container).to include_text('test comment')
    end
  end
end
