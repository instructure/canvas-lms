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

describe 'Account Notifications', :pact do
  subject(:notifications_api) { Helper::ApiClient::AccountNotifications.new }

  context 'List Notifications' do
    it 'should return JSON body' do
      canvas_lms_api.given('a user with many notifications').
        upon_receiving('List Notifications').
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
            "/api/v1/accounts/:{account_user_id}/account_notifications",
            { account_user_id: '1'}
          ),
          query: ''
        ).
        will_respond_with(
          status: 200,
          body: Pact.each_like(
            {
              'id': 1,
              'subject': 'something',
              'message': 'another',
              'start_at': 'start_date',
              'end_at': 'end_date',
              'icon': 'icon_sent'
            }
          )
        )

      response = notifications_api.list_account_notifications(1)
      expect(response[0]['subject']).to eq 'something'
      expect(response[0]['message']).to eq 'another'
    end
  end

  context 'Show Notification' do
    it 'should return JSON body' do
      canvas_lms_api.given('a user with many notifications').
        upon_receiving('Show Notification').
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
            "/api/v1/accounts/:{account_user_id}/account_notifications/:{notification1_id}",
            { account_user_id: '1', notification1_id: '1'}
          ),
          query: ''
        ).
        will_respond_with(
          status: 200,
          body: Pact.like(
            {
              'id': 1,
              'subject': 'something',
              'message': 'another',
              'start_at': 'start_date',
              'end_at': 'end_date',
              'icon': 'icon_sent'
            }
          )
        )

      response = notifications_api.show_account_notification(1, 1)
      expect(response['subject']).to eq 'something'
      expect(response['message']).to eq 'another'
    end
  end

  context 'Delete Notification' do
    it 'should return JSON body' do
      canvas_lms_api.given('a user with many notifications').
        upon_receiving('Delete Notification').
        with(
          method: :delete,
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
            "/api/v1/accounts/:{account_user_id}/account_notifications/:{notification3_id}",
            { account_user_id: '1', notification3_id: '3'}
          ),
          query: ''
        ).
        will_respond_with(
          status: 200,
          body: Pact.like(
            {
              'id': 1,
              'subject': 'something',
              'message': 'another',
              'start_at': 'start_date',
              'end_at': 'end_date',
              'icon': 'icon_sent'
            }
          )
        )

      response = notifications_api.remove_account_notification(1, 3)
      expect(response['subject']).to eq 'something'
      expect(response['message']).to eq 'another'
    end
  end

  context 'Post Notification' do
    it 'should return JSON body' do
      canvas_lms_api.given('a user with many notifications').
        upon_receiving('Post Notification').
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
            "/api/v1/accounts/:{account_user_id}/account_notifications",
            { account_user_id: '1'}
          ),
          'body' =>
          {
            'account_notification':
            {
              'subject': 'New notification',
              'start_at': '2014-01-01T00:00:00Z',
              'end_at': '2014-01-02T00:00:00Z',
              'message': 'This is a notification'
            }
          },
          query: ''
        ).
        will_respond_with(
          status: 200,
          body: Pact.like(
            {
              'id': 1,
              'subject': 'something',
              'message': 'another',
              'start_at': 'start_date',
              'end_at': 'end_date',
              'icon': 'icon_sent'
            }
          )
        )

      response = notifications_api.create_account_notification(1)
      expect(response['subject']).to eq 'something'
      expect(response['message']).to eq 'another'
    end
  end

  context 'Update Notification' do
    it 'should return JSON body' do
      canvas_lms_api.given('a user with many notifications').
        upon_receiving('Update Notification').
        with(
          method: :put,
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
            "/api/v1/accounts/:{account_user_id}/account_notifications/:{notification1_id}",
            { account_user_id: '1', notification1_id: '1'}
          ),
          'body' =>
          {
            # make sure the contents of account_notification matches the one in your API Client
            'account_notification':
            {
              'subject': 'Updated notification',
              'start_at': '2014-01-01T00:00:00Z',
              'end_at': '2014-01-02T00:00:00Z',
              'message': 'This is an updated notification'
            }
          },
          query: ''
        ).
        will_respond_with(
          status: 200,
          body: Pact.like(
            {
              'id': 1,
              'subject': 'something',
              'message': 'another',
              'start_at': 'start_date',
              'end_at': 'end_date',
              'icon': 'icon_sent'
            }
          )
        )
      response = notifications_api.update_account_notification(1,1)
      expect(response['subject']).to eq 'something'
      expect(response['message']).to eq 'another'
    end
  end
end
