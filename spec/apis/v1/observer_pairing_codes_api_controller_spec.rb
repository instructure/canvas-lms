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

describe ObserverPairingCodesApiController, type: :request do
  include Api

  describe '#create' do
    before :once do
      @student = student_in_course(active_all: true).user
      @path = "/api/v1/users/#{@student.id}/observer_pairing_codes"
      @params = {user_id: @student.to_param,
        controller: 'observer_pairing_codes_api', action: 'create', format: 'json'}
    end

    it 'students can create pairing codes for themselves' do
      json = api_call_as_user(@student, :post, @path, @params)
      expect(json['user_id']).to eq @student.id
      expect(json['expires_at'] >= 6.days.from_now && json['expires_at'] <= 7.days.from_now).to eq true
      expect(json['workflow_state']).to eq 'active'
      expect(json['code'].length).to eq 6
    end

    it 'errors if user_id passed in isnt a student' do
      user = user_model
      params = @params.merge(user_id: user.to_param)
      path = "/api/v1/users/#{user.id}/observer_pairing_codes"
      api_call_as_user(user, :post, path, params)
      expect(response.code).to eq "401"
    end

    it 'teacher cannot generate code by default' do
      teacher = teacher_in_course(course: @course, active_all: true).user
      json = api_call_as_user(teacher, :post, @path, @params)
      expect(response.code).to eq "401"
      expect(json['code']).to eq nil
    end

    it 'admin can generate code' do
      admin = account_admin_user(account: Account.default)
      json = api_call_as_user(admin, :post, @path, @params)
      expect(response.code).to eq "200"
      expect(json['code']).not_to be nil
    end

    it 'errors if current_user isnt the student or a teacher/admin' do
      api_call_as_user(user_model, :post, @path, @params)
      expect(response.code).to eq "401"
    end

    describe 'sub_accounts' do
      before :once do
        @sub_account = Account.create! root_account: Account.default
        @student = course_with_student(account: @sub_account, active_all: true).user
        @sub_admin = account_admin_user(account: @sub_account)
        @path = "/api/v1/users/#{@student.id}/observer_pairing_codes"
        @params = {user_id: @student.to_param,
          controller: 'observer_pairing_codes_api', action: 'create', format: 'json'}
      end

      it 'sub_account admin can generate code' do
        json = api_call_as_user(@sub_admin, :post, @path, @params)
        expect(response.code).to eq "200"
        expect(json['code']).not_to be nil
      end

      it "sub_account admin cant generate code for students in other sub accounts" do
        other_sub_account = Account.create! root_account: Account.default
        other_student = course_with_student(account: other_sub_account, active_all: true).user
        path = "/api/v1/users/#{other_student.id}/observer_pairing_codes"
        params = {user_id: other_student.to_param,
          controller: 'observer_pairing_codes_api', action: 'create', format: 'json'}
        api_call_as_user(@sub_admin, :post, path, params)
        expect(response.code).to eq "401"
      end
    end
  end
end
