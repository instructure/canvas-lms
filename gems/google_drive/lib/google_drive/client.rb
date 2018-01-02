#
# Copyright (C) 2015 - present Instructure, Inc.
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

module GoogleDrive
  class Client

    ##
    #
    # @param [Hash] client_secrets
    #   The parsed client_secrets.json file
    # @param [String] refresh_token
    #   Optional refresh_token
    # @param [String] access_token
    #  Optional access_token
    def self.create(client_secrets, refresh_token = nil, access_token = nil)
      name = "Instructure Google Drive"
      version = "0.0.1"
      # identical to the api default except for the .strip on OS_VERSION - ruby 2.5 doesn't like the \n
      user_agent = "#{name}/#{version} google-api-ruby-client/#{Google::APIClient::VERSION::STRING} #{Google::APIClient::ENV::OS_VERSION.strip} (gzip)"

      client = Google::APIClient.new(application_name: name, application_version: version, user_agent: user_agent)
      client.authorization.client_id = client_secrets['client_id']
      client.authorization.client_secret = client_secrets['client_secret']
      client.authorization.redirect_uri = client_secrets['redirect_uri']
      client.authorization.refresh_token = refresh_token if refresh_token
      client.authorization.access_token = access_token if access_token
      client.authorization.scope = %w{https://www.googleapis.com/auth/drive}
      client
    end

    def self.auth_uri(client, state, login=nil)
      auth_client = client.authorization
      auth_client.update!

      request_data = {
        :approval_prompt => :force,
        :state => state,
        :access_type => :offline
      }

      request_data[:login_hint] = login if login
      auth_client.authorization_uri(request_data).to_s
    end
  end
end
