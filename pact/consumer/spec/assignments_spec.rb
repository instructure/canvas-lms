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

require_relative '../assignments_api_client'
require_relative 'pact_helper'

describe 'Assignments', :pact => true do

  subject(:assignmentsApi) {AssignmentsApiClient.new}

  before do
    AssignmentsApiClient.base_uri 'localhost:1234'
  end

  context 'List Assignments' do
    it 'should return JSON body' do
      canvas_api.given('a student in a course with an assignment').
        upon_receiving('List Assignments').
        with(method: :get,
          headers: {
            "Authorization"  => Pact.term(
              generate: "Bearer token",
              matcher: /Bearer ([A-Za-z0-9]+)/
            ),
            "Connection": "close",
            "Host": "localhost:1234",
            "Version": "HTTP/1.1"
          },
          'path' => Pact.term(
            generate: '/api/v1/courses/1/assignments',
            matcher: /\/api\/v1\/courses\/[0-9]+\/assignments/
          ),
          query: ''
        ).
        will_respond_with(
          status: 200,
          body: Pact.each_like(
            "id":5,
            "name":"some assignment"
          )
        )

      response = assignmentsApi.list_assignments(1)
      expect(response[0]['id']).to eq 5
      expect(response[0]['name']).to eq 'some assignment'
    end
  end
end
