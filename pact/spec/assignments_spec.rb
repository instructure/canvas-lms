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

describe 'Assignments', :pact do

  subject(:assignments_api) { Helper::ApiClient::Assignments.new }

  context 'List Assignments' do
    it 'should return JSON body' do
      canvas_lms_api.given('a student in a course with an assignment').
        upon_receiving('List Assignments').
        with(
          method: :get,
          headers: {
            'Authorization' => Pact.provider_param(
              'Bearer :{token}',
              { token: 'some_token' }
            ),
            'Connection': 'close',
            'Host': PactConfig.mock_provider_service_base_uri,
            'Version': 'HTTP/1.1'
          },
          'path' => Pact.provider_param(
            "/api/v1/users/:{user_id}/courses/:{course_id}/assignments",
            { user_id: '1', course_id: '1' }
          ),
          query: ''
        ).
        will_respond_with(
          status: 200,
          body: Pact.each_like('id': 1, 'name': 'Assignment1')
        )

      response = assignments_api.list_assignments(1, 1)
      expect(response[0]['id']).to eq 1
      expect(response[0]['name']).to eq 'Assignment1'
    end
  end

  context 'Post Assignments' do
    it 'should return JSON body' do
      canvas_lms_api.given('a teacher in a course').
        upon_receiving('Post Assignments').
        with(
          method: :post,
          headers: {
            'Authorization' => Pact.provider_param(
              'Bearer :{token}',
              { token: 'some_token' }
            ),
            'Connection': 'close',
            'Host': PactConfig.mock_provider_service_base_uri,
            'Version': 'HTTP/1.1',
            'Content-Type': 'application/json'
          },
          'path' => Pact.provider_param(
            "/api/v1/courses/:{course_id}/assignments",
            { course_id: '1' }
          ),
          'body' =>
            {
              'assignment':
                {
                  'name': 'New Assignment'
                }
            },

          query: ''
        ).
        will_respond_with(
          status: 201,
          body: Pact.like('id': 1, 'name': 'New Assignment')
        )

      response = assignments_api.post_assignments(1, 'New Assignment')
      expect(response['id']).to eq 1
      expect(response['name']).to eq 'New Assignment'
    end
  end
end
