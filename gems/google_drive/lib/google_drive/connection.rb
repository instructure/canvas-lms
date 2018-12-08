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

require 'google/api_client/errors'

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
      'google_drive'
    end

    def with_timeout_protection
      Timeout.timeout(@timeout || 30) { yield }
    rescue Timeout::Error
      raise ConnectionException, 'Google Drive connection timed out'
    end

    def client_execute(options)
      with_timeout_protection { with_retries { api_client.execute(options) } }
    end

    def client_execute!(options)
      with_timeout_protection { with_retries { api_client.execute!(options) } }
    end

    def force_token_update
      with_timeout_protection { api_client.authorization.update_token! }
    end

    def download(document_id, extensions)
      response = client_execute!(
        :api_method => drive.files.get,
        :parameters => { :fileId => normalize_document_id(document_id) }
      )

      file = response.data.to_hash
      entry = GoogleDrive::Entry.new(file, extensions)
      result = client_execute(:uri => entry.download_url)
      if result.status == 200
        file_name = file['title']
        name_extension = file_name[/\.([a-z]+$)/, 1]
        file_extension = name_extension || file_extension_from_header(result.headers, entry)

        # file_name should contain the file_extension
        file_name += ".#{file_extension}" unless name_extension
        content_type = result.headers['Content-Type'].sub(/; charset=[^;]+/, '')
        [result, file_name, file_extension, content_type]
      else
        raise ConnectionException, result.error_message
      end
    end

    def list_with_extension_filter(extensions)
      list extensions
    end

    def create_doc(name)
      file_data = {
        :title => name,
        :mimeType => 'application/vnd.google-apps.document'
      }

      force_token_update
      file = drive.files.insert.request_schema.new(file_data)

      result = client_execute(
        :api_method => drive.files.insert,
        :body_object => file
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
        :api_method => drive.files.delete,
        :parameters => { :fileId => normalize_document_id(document_id) })
      if result.error? && !result.error_message.include?('File not found')
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
          :api_method => drive.permissions.delete,
          :parameters => {
            :fileId => normalize_document_id(document_id),
            :permissionId => user_id })
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
           :id => user_id,
           :type => 'user',
           :role => 'writer'
        })
        result = client_execute(
          :api_method => drive.permissions.insert,
          :body_object => new_permission,
          :parameters => { :fileId => normalize_document_id(document_id)}
        )
        if result.error?
          raise ConnectionException, result.error_message
        end
      end
    end

    def authorized?
      force_token_update
      client_execute(:api_method => drive.about.get).status == 200
    rescue ConnectionException, NoTokenError, Google::APIClient::AuthorizationError
      false
    end

    def self.config_check(_settings)
      raise ConnectionException("No config check")
    end

    def self.config=(config)
      unless config.is_a?(Proc)
        raise 'Config must be a Proc'
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
        sleep attempts ** 2
        retry
      end

      raise
    end

    def list(extensions)
      client_params = {
        api_method: drive.files.list,
        parameters: { maxResults: 0, q: 'trashed=false' }
      }
      list_data = client_execute!(client_params).data.to_hash
      folderize_list(list_data, extensions)
    end

    def normalize_document_id(doc_id)
      doc_id.gsub(/^.+:/, '')
    end

    def folderize_list(documents, extensions)
      root = GoogleDrive::Folder.new('/')
      folders = {nil => root}

      documents['items'].each do |doc_entry|
        next unless doc_entry['downloadUrl'] || doc_entry['exportLinks']
        entry = GoogleDrive::Entry.new(doc_entry, extensions)
        if folders.key?(entry.folder)
          folder = folders[entry.folder]
        else
          folder = GoogleDrive::Folder.new(get_folder_name_by_id(documents['items'], entry.folder))
          root.add_folder folder
          folders[entry.folder] = folder
        end
        is_folder = doc_entry['mimeType'] && doc_entry['mimeType'] == 'application/vnd.google-apps.folder'
        folder.add_file(entry) unless is_folder
      end

      if extensions && extensions.length > 0
        root = root.select { |e| extensions.include?(e.extension) }
      end

      root
    end

    def get_folder_name_by_id(entries, folder_id)
      elements = entries.select do |entry|
        entry['id'] == folder_id
      end
      elements.first ? elements.first['title'] : 'Unknown Folder'
    end

    def api_client
      raise ConnectionException, "GoogleDrive is not configured" if GoogleDrive::Connection.config.nil?
      raise NoTokenError unless @refresh_token && @access_token
      @api_client ||= GoogleDrive::Client.create(GoogleDrive::Connection.config, @refresh_token, @access_token)
    end

    def drive
      @drive ||= Rails.cache.fetch('google_drive_v2') do
        api_client.discovered_api('drive', 'v2')
      end
    end

    def file_extension_from_header(headers, entry)
      file_extension = entry.extension && !entry.extension.empty? && entry.extension || 'unknown'

      if headers['content-disposition'] &&
        headers['content-disposition'].match(/filename=[\"\']?[^;\"\'\.]+\.(?<file_extension>[^;\"\']+)[\"\']?/)
        file_extension = Regexp.last_match[:file_extension]
      end

      file_extension
    end
  end
end
