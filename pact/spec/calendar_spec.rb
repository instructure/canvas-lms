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

#require_relative '../calendar_api_client'
require_relative 'helper'
require_relative '../pact_helper'

describe 'Calendar', :pact => true do

  subject(:calendar_api) {Helper::ApiClient::Calendar.new}

  context 'Show Calendar Event' do
    it 'should return JSON body' do
      canvas_lms_api.given('a user with a calendar event').
        upon_receiving('Show Calendar Event').
        with(method: :get,
          headers: {
            'Authorization' => Pact.provider_param(
              'Bearer :{token}',
              {token: 'some_token'} 
            ),
            'Connection': 'close',
            'Host': PactConfig.mock_provider_service_base_uri,
            'Version': 'HTTP/1.1'
          },
          'path' => Pact.provider_param(
            "/api/v1/calendar_events/:{event_id}",
            {event_id: '1'}),
          query: '').will_respond_with(
            status: 200,
            body: Pact.like(
              {'id':1, 'title': 'something'})#,
              #'start_at': '2018-07-20T05:59:00Z',
              #'end_at': '2018-07-20T05:59:00Z',
              #'description': 'another thing',
              #'context_code': 'course_1',
              #'workflow_state': 'active',
              #'url': Pact.provider_param("<canvas>/api/v1/calendar_events/:{event_id}",
              #{event_id: '1'}),
              #'html_url': Pact.provider_param("<canvas>/api/v1/calendar_events/:{event_id}",
              #{event_id: '1'}),
              #'all_day_date': nil,
              #'all_day': false =end
            #)
          )
      response = calendar_api.show_calendar_event(1)
      expect(response['id']).to eq 1
      expect(response['title']).to eq 'something'
      #expect(response[0]['contex_code']).to eq @course.id
    end
  end

  context 
end
