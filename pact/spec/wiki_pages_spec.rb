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

describe 'Wiki Pages', :pact do
  subject(:wiki_page_api) { Helper::ApiClient::WikiPages.new }

  it 'should List Wiki Pages' do
    canvas_lms_api.given('a wiki page in a course').
      upon_receiving('List Wiki Pages').
      with(
        method: :get,
        headers: {
          'Authorization': 'Bearer some_token',
          'Auth-User': 'Teacher1',
          'Connection': 'close',
          'Host': PactConfig.mock_provider_service_base_uri,
          'Version': 'HTTP/1.1'
        },
        'path' => '/api/v1/courses/1/pages/',
        query: ''
      ).
      will_respond_with(
        status: 200,
        body: Pact.each_like(
          "title": "WIKI Page",
          "created_at": "2018-05-30T22:50:18Z",
          "url": "wiki-page",
          "editing_roles": "teachers",
          "page_id": 1,
          "published": true,
          "hide_from_students": false,
          "front_page": false,
          "html_url": "http://localhost:3000/courses/3/pages/wiki-page",
          "updated_at": "2018-05-30T22:50:18Z",
          "locked_for_user": false
        )
      )
      wiki_page_api.authenticate_as_user('Teacher1')
    response = wiki_page_api.list_wiki_pages(1)
    expect(response[0]['title']).to eq "WIKI Page"
  end
end
