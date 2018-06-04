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

RSpec.shared_examples 'a provisional grades status action' do |controller|
  describe "status" do
    before(:once) do
      course_with_teacher(active_all: true)
      ta_in_course(active_all: true)
      @student = student_in_course(active_all: true).user
      @assignment = @course.assignments.create!(moderated_grading: true)
      @submission = @assignment.submit_homework @student, body: 'EHLO'
      @path = "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/#{controller}/status"
      @resource_pair = if controller == :anonymous_provisional_grades
        { anonymous_id: @submission.anonymous_id }
      else
        { student_id: @submission.user_id }
      end
      @params = {
        controller: controller,
        action: :status,
        format: :json,
        course_id: @course.to_param,
        assignment_id: @assignment.to_param
      }.merge(@resource_pair)
    end

    it "gives a status message of unauthorized when called as a student" do
      json = api_call_as_user(@student, :get, @path, @params, {}, {}, { expected_status: 401 })
      expect(json['status']).to eq 'unauthorized'
    end

    it "gives an error message of unauthorized when called as a student" do
      json = api_call_as_user(@student, :get, @path, @params, {}, {}, { expected_status: 401 })
      expect(json.fetch('errors')).to include({'message' => 'user not authorized to perform that action'})
    end

    it 'when given a TA, it needs a provisional grade' do
      json = api_call_as_user(@ta, :get, @path, @params, {}, {}, { expected_status: 200 })
      expect(json['needs_provisional_grade']).to be true
    end

    it 'when given a TA and a selection exists, it needs a provisional grade' do
      @assignment.moderated_grading_selections.create!(student: @student)
      json = api_call_as_user(@ta, :get, @path, @params, {}, {}, { expected_status: 200 })
      expect(json['needs_provisional_grade']).to be true
    end

    it 'when given a TA and a teacher-created provisional grade exists, it does not need a provisional grade' do
      @submission.find_or_create_provisional_grade!(@teacher)
      json = api_call_as_user(@ta, :get, @path, @params, {}, {}, { expected_status: 200 })
      expect(json['needs_provisional_grade']).to be false
    end

    it 'when given a TA and a TA-created provisional grade, it does not need a provisional grade' do
      @submission.find_or_create_provisional_grade!(@ta)
      json = api_call_as_user(@ta, :get, @path, @params, {}, {}, { expected_status: 200 })
      expect(json['needs_provisional_grade']).to be false
    end

    it 'when called as a student, error message is not found' do
      @params[@resource_pair.flatten.first] = nil
      json = api_call_as_user(@ta, :get, @path, @params, {}, {}, { expected_status: 404 })
      expect(json.fetch('errors')).to include({'message' => 'The specified resource does not exist.'})
    end
  end
end
