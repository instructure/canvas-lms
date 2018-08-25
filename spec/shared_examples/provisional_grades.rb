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
      @assignment = @course.assignments.create!(moderated_grading: true, grader_count: 2)
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

    it 'when called as a student, error message is not found' do
      @params[@resource_pair.flatten.first] = nil
      json = api_call_as_user(@ta, :get, @path, @params, {}, {}, { expected_status: 404 })
      expect(json.fetch('errors')).to include({'message' => 'The specified resource does not exist.'})
    end

    it 'is authorized when the user is an admin with permission to select final grade' do
      admin = account_admin_user(account: @course.account)
      api_call_as_user(admin, :get, @path, @params.merge(last_updated_at: 1.day.ago(@submission.updated_at)), {}, {})
      expect(response).to be_success
    end

    it 'is unauthorized when the user is an admin without permission to select final grade' do
      admin = account_admin_user(account: @course.account)
      @course.account.role_overrides.create!(role: admin_role, enabled: false, permission: :select_final_grade)
      api_call_as_user(admin, :get, @path, @params.merge(last_updated_at: 1.day.ago(@submission.updated_at)), {}, {})
      expect(response).to be_unauthorized
    end

    context 'when called as a moderator' do
      let(:provisional_grades_json) do
        json = api_call_as_user(@teacher, :get, @path, @params, {}, {}, { expected_status: 200 })
        json.fetch('provisional_grades')
      end

      before(:once) do
        @assignment.update!(grader_count: 1, final_grader: @teacher)

        @ta.update!(name: 'Nobody Important')
        @submission.find_or_create_provisional_grade!(@ta)
        @params.merge!(last_updated_at: @submission.updated_at-1)
      end

      it 'omits the scorer_name parameter from provisional grades if the final grader cannot view grader names' do
        @assignment.update!(grader_names_visible_to_final_grader: false)
        expect(provisional_grades_json.first).not_to have_key('scorer_name')
      end

      it 'includes the scorer_name parameter for provisional grades if the final grader can view grader names' do
        @assignment.update!(grader_names_visible_to_final_grader: true)
        expect(provisional_grades_json.first['scorer_name']).to eq 'Nobody Important'
      end
    end
  end
end
