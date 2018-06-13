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

RSpec.shared_examples 'authorization when Anonymous Moderated Marking is enabled' do |http_verb|
  before(:once) { @course.root_account.enable_feature!(:anonymous_moderated_marking) }

  it 'is unauthorized if the user is not the assigned final grader' do
    api_call_as_user(@teacher, http_verb, @path, @params, {}, {}, expected_status: 401)
  end

  it 'is unauthorized if the user is an account admin without "Select Final Grade for Moderation" permission' do
    @course.account.role_overrides.create!(role: admin_role, enabled: false, permission: :select_final_grade)
    api_call_as_user(account_admin_user, http_verb, @path, @params, {}, {}, expected_status: 401)
  end

  it 'is authorized if the user is the final grader' do
    @assignment.update!(final_grader: @teacher, grader_count: 2)
    api_call_as_user(@teacher, http_verb, @path, @params, {}, {}, expected_status: 200)
  end

  it 'is authorized if the user is an account admin with "Select Final Grade for Moderation" permission' do
    api_call_as_user(account_admin_user, http_verb, @path, @params, {}, {}, expected_status: 200)
  end
end
