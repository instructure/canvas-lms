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
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe GradebooksController, type: :request do
  before :once do
    course_with_teacher active_all: true
    @teacher_enrollment = @enrollment
    student_in_course active_all: true
    @student_enrollment = @enrollment
  end

  describe 'GET #speed_grader' do
    before :once do
      @assignment = @course.assignments.create!(
        title: 'A Title', submission_types: 'online_url', grading_type: 'percent'
      )
    end

    before :each do
      user_session(@teacher)
    end

    describe 'js_env' do
      describe 'can_comment_on_submission' do
        it 'is false if the course is concluded' do
          @course.complete
          get speed_grader_course_gradebook_path(course_id: @course.id), params: { assignment_id: @assignment.id }

          expect(response.body).to include('"can_comment_on_submission":false')
        end

        it 'is false if the teacher enrollment is concluded' do
          @teacher_enrollment = @course.teacher_enrollments.find_by(user: @teacher)
          @teacher_enrollment.conclude
          get speed_grader_course_gradebook_path(course_id: @course.id), params: { assignment_id: @assignment.id }

          expect(response.body).to include('"can_comment_on_submission":false')
        end

        it 'is true otherwise' do
          get speed_grader_course_gradebook_path(course_id: @course.id), params: { assignment_id: @assignment.id }

          expect(response.body).to include('"can_comment_on_submission":true')
        end
      end
    end
  end
end
