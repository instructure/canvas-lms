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

describe 'Account Reports', :pact do

  subject(:account_reports_api) { Helper::ApiClient::AccountReports.new }

  context 'List Reports' do
    it 'should return JSON body' do
      canvas_lms_api.given('a user with many account reports').
        upon_receiving('List Reports').
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
            "/api/v1/accounts/:{account_user_id}/reports",
            {account_user_id: '1' }
          ),
          query: ''
        ).
        will_respond_with(
          status: 200,
          body: Pact.each_like(
            'title': 'a title',
            'report': 'report_type'
          )
        )

      response = account_reports_api.list_reports(1)
      expect(response[0]['title']).to eq 'a title'
      expect(response[0]['report']).to eq 'report_type'
    end
  end

  context 'Show Report' do
    it 'should return JSON body' do
      canvas_lms_api.given('a user with many account reports').
        upon_receiving('Show Reports').
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
            "/api/v1/accounts/:{account_user_id}/reports/:{report_type}/:{report_id}",
            {account_user_id: '1', report_type: 'report_type', report_id: '1'}
          ),
          query: ''
        ).
        will_respond_with(
          status: 200,
          body: Pact.like(
            'id': 1,
            'report': 'report_type',
            'created_at': 'blah',
            'started_at': 'start_time',
            'ended_at': 'end_time',
            'status': 'created'
          )
        )

      response = account_reports_api.show_report(1,'report_type',1)
      expect(response['id']).to eq 1
      expect(response['report']).to eq 'report_type'
    end
  end
end
