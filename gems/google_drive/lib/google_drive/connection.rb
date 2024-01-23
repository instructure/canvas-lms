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

module GoogleDrive
  class Connection
    def initialize(refresh_token, access_token, timeout = nil, retries: 3)
      @refresh_token = refresh_token
      @access_token = access_token
      @timeout = timeout || 30
      @retries = retries
    end

    def service_type
      "google_drive"
    end

    def force_token_update
      return if drive.authorization.expires_at && !drive.authorization.expired?

      drive.authorization.refresh!
    end

    def create_doc(name)
      file = Google::Apis::DriveV3::File.new(name:,
                                             mime_type: "application/vnd.google-apps.document")

      force_token_update
      drive.create_file(file, fields: "id,webViewLink")
    rescue Google::Apis::Error => e
      raise ConnectionException, exception_message(e)
    end

    def delete_doc(document_id)
      force_token_update
      drive.delete_file(normalize_document_id(document_id))
    rescue Google::Apis::Error => e
      return if e.status_code == 404

      raise ConnectionException, exception_message(e)
    end

    def acl_remove(document_id, users)
      document_id = normalize_document_id(document_id)

      force_token_update

      users.each do |user_id|
        drive.delete_permission(document_id, user_id)
      rescue Google::Apis::Error => e
        next if e.status_code == 404

        raise ConnectionException, exception_message(e)
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
        new_permission = Google::Apis::DriveV3::Permission.new(
          email_address: user_id,
          type: "user",
          role: "writer"
        )
        drive.create_permission(normalize_document_id(document_id), new_permission)
      rescue Google::Apis::Error => e
        raise ConnectionException, exception_message(e)
      end
    end

    def authorized?
      drive.get_about(fields: "user")
      true
    rescue ConnectionException, NoTokenError, Google::Apis::Error
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

    def exception_message(exception)
      return "Google Drive connection timed out" if exception.cause.is_a?(HTTPClient::TimeoutError)

      JSON.parse(exception.body).dig("error", "message")
    rescue JSON::ParserError, TypeError
      exception.message
    end

    def normalize_document_id(doc_id)
      doc_id.gsub(/^.+:/, "")
    end

    def drive
      raise ConnectionException, "GoogleDrive is not configured" if GoogleDrive::Connection.config.nil?
      raise NoTokenError unless @refresh_token && @access_token

      @drive ||= GoogleDrive::Client.create(GoogleDrive::Connection.config, @refresh_token, @access_token).tap do |drive|
        drive.client_options.open_timeout_sec =
          drive.client_options.send_timeout_sec =
            drive.client_options.read_timeout_sec = @timeout
        drive.request_options.retries = @retries
      end
    end
  end
end
