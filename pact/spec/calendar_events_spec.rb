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

describe 'Calendar Events', :pact => true do
  subject(:calendar_events_api) {Helper::ApiClient::CalendarEvents.new}

  it 'Should Show a Calender Event' do
    canvas_lms_api.given('a user with a robust calendar event').
      upon_receiving('Show Calendar a Event').
      with(method: :get,
        headers: {
          'Authorization': 'Bearer some_token',
          'Auth-User': 'Teacher1',
          'Connection': 'close',
          'Host': PactConfig.mock_provider_service_base_uri,
          'Version': 'HTTP/1.1'
        },
        'path' => "/api/v1/calendar_events/1",
        query: '').will_respond_with(
          status: 200,
          body:
            {
              'id': Pact.like(1), # int
              'title': Pact.like('something'), # string
              'start_at': Pact.term(
                generate: '2018-07-20T05:59:00Z',
                matcher: /(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})Z/
              ), # date regex
              'end_at': Pact.term(
                generate: '2018-07-20T05:59:00Z',
                matcher: /(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})Z/
              ), # date regex
              'description': Pact.like('another thing'), # string
              'location_name': Pact.like('a location name'), # string
              'location_address': Pact.like('a location address'), # string
              'context_code': Pact.term(
                generate: 'course_1',
                matcher: /([a-zA-Z]+_)*\d+/
              ), # regex string_1
              'effective_context_code': Pact.term(
                generate: 'somecontextcode_1',
                matcher: /([a-zA-Z]+_)*\d+/
              ), # regex string1
              'all_context_codes': Pact.term(
                generate: 'courses_1,save_me_1',
                matcher: /(([a-zA-Z]+_)+\d+,?)*/
              ), # regex comma separated string
              'workflow_state': Pact.like('active'), # string
              'hidden': Pact.like(false), # bool
              'child_events_count': Pact.like(1), # int
              'child_events': Pact.each_like(
                'id': 6,
                'parent_event_id': 1,
                'title': 'What a life',
                'start_at': 'date_time',
                'end_at': 'date_time',
                'workflow_state': 'active',
                'created_at': 'date_time',
                'updated_at': 'date_time',
                'all_day': false
              ),
              'url': Pact.like('https://example.com'), # string
              'html_url': Pact.like('https://example.com'), # string
              'all_day_date': Pact.term(
                generate: '2012-07-19',
                matcher: /\d{4}-\d{2}-\d{2}/
              ), # date
              'all_day': Pact.like(false), # bool
              'created_at': Pact.term(
                generate: '2018-07-20T05:59:00Z',
                matcher: /(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})Z/
              ), # date regex
              'updated_at': Pact.term(
                generate: '2018-07-20T05:59:00Z',
                matcher: /(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})Z/
              ), # date regex
              'appointment_group_id': Pact.like(1), # int
              'appointment_group_url': Pact.like('https://example.com'), # string
              'reserve_url': Pact.like('https://example.com'), # string
              'participant_type': Pact.like('User'), # string
              'participants_per_appointment': Pact.like(1), # int or null
              'available_slots': Pact.like(1) # int or null
            }
        )
    calendar_events_api.authenticate_as_user('Teacher1')
    response = calendar_events_api.show_calendar_event(1)
    expect(response['id']).to eq 1
    expect(response['title']).to eq 'something'
  end
end
