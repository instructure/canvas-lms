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
#

# See Google Drive API documentation here:
# https://developers.google.com/drive/v2/web/about-sdk

require "google/api_client/errors"

module GoogleDrive
  class Connection
    def initialize(refresh_token, access_token, timeout = nil, retries: 3)
      @refresh_token = refresh_token
      @access_token = access_token
      @timeout = timeout
      @retries = retries
    end

    def retrieve_access_token
      @access_token || api_client
    end

    def service_type
      "google_drive"
    end

    def with_timeout_protection(&)
      Timeout.timeout(@timeout || 30, &)
    rescue Timeout::Error
      raise ConnectionException, "Google Drive connection timed out"
    end

    def client_execute(options)
      with_timeout_protection { with_retries { api_client.execute(options) } }
    end

    def force_token_update
      with_timeout_protection { api_client.authorization.update_token! }
    end

    def create_doc(name)
      file_data = {
        title: name,
        mimeType: "application/vnd.google-apps.document"
      }

      force_token_update
      file = drive.files.insert.request_schema.new(file_data)

      result = client_execute(
        api_method: drive.files.insert,
        body_object: file
      )

      if result.status == 200
        result
      else
        raise ConnectionException, result.error_message
      end
    end

    def delete_doc(document_id)
      force_token_update
      result = client_execute(
        api_method: drive.files.delete,
        parameters: { fileId: normalize_document_id(document_id) }
      )
      if result.error? && !result.error_message.include?("File not found")
        raise ConnectionException, result.error_message
      end
    end

    def acl_remove(document_id, users)
      force_token_update
      users.each do |user_id|
        # google drive ids are numeric, google docs are emails. if it is a google doc email just skip it
        # this is needed for legacy purposes
        next if user_id.blank? || /@/.match(user_id)

        result = client_execute(
          api_method: drive.permissions.delete,
          parameters: {
            fileId: normalize_document_id(document_id),
            permissionId: user_id
          }
        )
        if result.error? && !result.error_message.starts_with?("Permission not found")
          raise ConnectionException, result.error_message
        end
      end
    end

    # Public: Add users to a Google Doc ACL list.
    #
    # document_id - The id of the Google Doc to add users to.
    # users - An array of user objects.
    # domain - The string domain to restrict additions to (e.g. "example.com").
    #   Accounts not on this domain will be ignored.
    #
    # Returns nothing.
    def acl_add(document_id, users, _domain = nil)
      # TODO: support domain
      force_token_update
      users.each do |user_id|
        new_permission = drive.permissions.insert.request_schema.new({
                                                                       id: user_id,
                                                                       type: "user",
                                                                       role: "writer"
                                                                     })
        result = client_execute(
          api_method: drive.permissions.insert,
          body_object: new_permission,
          parameters: { fileId: normalize_document_id(document_id) }
        )
        if result.error?
          raise ConnectionException, result.error_message
        end
      end
    end

    def authorized?
      force_token_update
      client_execute(api_method: drive.about.get).status == 200
    rescue ConnectionException, NoTokenError, Google::APIClient::AuthorizationError
      false
    end

    def self.config_check(_settings)
      raise ConnectionException("No config check")
    end

    def self.config=(config)
      unless config.is_a?(Proc)
        raise "Config must be a Proc"
      end

      @config = config
    end

    def self.config
      @config.call
    end

    private

    # Retry on 4xx and 5xx status codes
    def with_retries
      attempts ||= 0
      yield
    rescue Google::APIClient::ClientError, Google::APIClient::ServerError
      if (attempts += 1) <= @retries
        sleep attempts**2
        retry
      end

      raise
    end

    def normalize_document_id(doc_id)
      doc_id.gsub(/^.+:/, "")
    end

    def api_client
      raise ConnectionException, "GoogleDrive is not configured" if GoogleDrive::Connection.config.nil?
      raise NoTokenError unless @refresh_token && @access_token

      @api_client ||= GoogleDrive::Client.create(GoogleDrive::Connection.config, @refresh_token, @access_token)
    end

    def drive
      @drive ||= Rails.cache.fetch("google_drive_v2") do
        api_client.discovered_api("drive", "v2")
      end
    end
  end
end
