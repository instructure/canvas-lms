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

require 'httparty'
require 'json'
require_relative '../../../pact_config'
require_relative '../api_client_base'

module Helper
  module ApiClient
    class AccountNotifications < ApiClientBase
      include HTTParty
      base_uri PactConfig.mock_provider_service_base_uri
      headers 'Authorization' => 'Bearer some_token'

      def list_account_notifications(account_id)
        JSON.parse(self.class.get("/api/v1/accounts/#{account_id}/account_notifications").body)
      rescue
        nil
      end

      def show_account_notification(account_id, notification_id)
        JSON.parse(self.class.get("/api/v1/accounts/#{account_id}/account_notifications/#{notification_id}").body)
      rescue
        nil
      end

      def remove_account_notification(account_id, notification_id)
        JSON.parse(self.class.delete("/api/v1/accounts/#{account_id}/account_notifications/#{notification_id}").body)
      rescue
        nil
      end

      def create_account_notification(account_id)
        JSON.parse(
          self.class.post("/api/v1/accounts/#{account_id}/account_notifications",
          :body =>
          {
            :account_notification =>
            {
              :subject => 'New notification',
              :start_at => '2014-01-01T00:00:00Z',
              :end_at => '2014-01-02T00:00:00Z',
              :message => 'This is a notification'
            }
          }.to_json,
          :headers => {'Content-Type' => 'application/json'}).body
        )
      rescue
        nil
      end

      def update_account_notification(account_id, notification_id)
        JSON.parse(self.class.put("/api/v1/accounts/#{account_id}/account_notifications/#{notification_id}",
        :body =>
        {
          :account_notification =>
          {
            :subject => 'Updated notification',
            :start_at => '2014-01-01T00:00:00Z',
            :end_at => '2014-01-02T00:00:00Z',
            :message => 'This is an updated notification'
          }
        }.to_json,
        :headers => {'Content-Type' => 'application/json'}).body)
      rescue
        nil
      end
    end
  end
end
