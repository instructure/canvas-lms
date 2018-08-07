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

describe 'Searches', :pact do
  subject(:search_api) { Helper::ApiClient::Search.new }

  it 'should Search For Users' do
    canvas_lms_api.given('a teacher enrolled in a course').
      upon_receiving('Search For Users').
      with(
        method: :get,
        headers: {
          'Authorization': 'Bearer some_token',
          'Auth-User': 'Teacher1',
          'Connection': 'close',
          'Host': PactConfig.mock_provider_service_base_uri,
          'Version': 'HTTP/1.1'
        },
        path: '/api/v1/search/recipients',
        query: 'search=Student1'
      ).
      will_respond_with(
        status: 200,
        body: Pact.like(
          [
            "id": 5,
            "name": "Student1",
            "full_name": "Student1",
            "common_courses": {
              "1": [
                "StudentEnrollment"
              ]
            },
            "common_groups": {},
            "avatar_url": "http://localhost:1234/images/messages/avatar-50.png"
          ]
        )
      )
    search_api.authenticate_as_user('Teacher1')
    response = search_api.search("Student1")
    expect(response[0]['name']).to eq "Student1"
  end

  it 'should Search For Courses' do
    canvas_lms_api.given('a teacher enrolled in a course').
      upon_receiving('Search For Courses').
      with(
        method: :get,
        headers: {
          'Authorization': 'Bearer some_token',
          'Auth-User': 'Teacher1',
          'Connection': 'close',
          'Host': PactConfig.mock_provider_service_base_uri,
          'Version': 'HTTP/1.1'
        },
        path: '/api/v1/search/recipients',
        query: 'search=course'
      ).
      will_respond_with(
        status: 200,
        body: Pact.like(
          [
            {
              "id": "course_1",
              "name": "Contract Tests Course",
              "avatar_url": "http://localhost:1234/images/messages/avatar-group-50.png",
              "type": "context",
              "user_count": 4,
              "permissions": {}
            },
          ]
        )
      )
    search_api.authenticate_as_user('Teacher1')
    response = search_api.search("course")
    expect(response[0]['name']).to eq "Contract Tests Course"
  end
end


