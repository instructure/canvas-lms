# frozen_string_literal: true

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
      drive = Google::Apis::DriveV3::DriveService.new
      scopes = [Google::Apis::DriveV3::AUTH_DRIVE_APPDATA, Google::Apis::DriveV3::AUTH_DRIVE_FILE]
      authorizer = Google::Auth::UserRefreshCredentials.new(
        client_id: client_secrets["client_id"],
        client_secret: client_secrets["client_secret"],
        redirect_uri: client_secrets["redirect_uri"],
        scope: scopes
      )

      authorizer.refresh_token = refresh_token if refresh_token
      authorizer.access_token = access_token if access_token
      drive.authorization = authorizer
      drive
    end

    def self.auth_uri(drive, state, login = nil)
      authorizer = drive.authorization

      request_data = {
        approval_prompt: :force,
        state:,
        access_type: :offline
      }

      request_data[:login_hint] = login if login
      authorizer.authorization_uri(request_data).to_s
    end
  end
end
