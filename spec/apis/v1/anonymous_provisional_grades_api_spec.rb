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
#

require_relative '../api_spec_helper'

describe 'Anonymous Provisional Grades API', type: :request do
  it_behaves_like 'a provisional grades status action', :anonymous_provisional_grades

  describe 'status' do
    before(:once) do
      course_with_teacher(active_all: true)
      @course.account.enable_service(:avatars)
      ta_in_course(active_all: true)
      @student = student_in_course(active_all: true).user
      @assignment = @course.assignments.create!(moderated_grading: true, grader_count: 1)
      @submission = @assignment.submit_homework(@student, body: 'EHLO')
      @path = "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/anonymous_provisional_grades/status"
      @params = {
        controller: :anonymous_provisional_grades,
        action: :status,
        format: :json,
        course_id: @course.to_param,
        assignment_id: @assignment.to_param,
        anonymous_id: @submission.anonymous_id
      }
    end

    it 'requires authorization' do
      json = api_call_as_user(@student, :get, @path, @params, {}, {}, { expected_status: 401 })
      expect(json['status']).to eq 'unauthorized'
      expect(json.fetch('errors')).to include({'message' => 'user not authorized to perform that action'})
    end
  end
end

