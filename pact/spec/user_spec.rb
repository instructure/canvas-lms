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

require_relative 'helper'
require_relative '../pact_helper'

describe 'Users', :pact do
  subject(:users_api) { Helper::ApiClient::Users.new }

  it 'should List To Do Count for User' do
    canvas_lms_api.given('a student enrolled in a course').
      upon_receiving('List To Do Count for User').
      with(
        method: :get,
        headers: {
          'Authorization': 'Bearer some_token',
          'Auth-User': 'Student1',
          'Connection': 'close',
          'Host': PactConfig.mock_provider_service_base_uri,
          'Version': 'HTTP/1.1'
        },
        path: '/api/v1/users/self/todo_item_count',
        query: ''
      ).
      will_respond_with(
        status: 200,
        body: Pact.like(
          needs_grading_count: 0,
          assignments_needing_submitting: 0
        )
      )
    users_api.authenticate_as_user('Student1')
    response = users_api.list_to_do_count()
    expect(response['needs_grading_count']).to eq 0
    expect(response['assignments_needing_submitting']).to eq 0
  end
end


