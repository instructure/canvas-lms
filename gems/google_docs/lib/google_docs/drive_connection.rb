#
# Copyright (C) 2011 Instructure, Inc.
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

# See Google Docs API documentation here:
# http://code.google.com/apis/documents/docs/2.0/developers_guide_protocol.html
module GoogleDocs
  class DriveConnectionException < RuntimeError
  end

  class DriveConnection
    def initialize(refresh_token, access_token)
      @refresh_token = refresh_token
      @access_token = access_token
    end

    def retrieve_access_token
      @access_token || api_client
    end

    def service_type
      'google_drive'
    end

    def download(document_id, extensions)
      response = api_client.execute!(
        :api_method => drive.files.get,
        :parameters => { :fileId => document_id }
      )

      file = response.data.to_hash
      entry = GoogleDocs::DriveEntry.new(file, extensions)
      result = api_client.execute(:uri => entry.download_url)
      if result.status == 200

        # hack to make it seem like the old object
        result.define_singleton_method(:content_type) do
          result.headers['Content-Type']
        end

        # TODO: get extension from response header
        [result, file['title'],  entry.extension]
      else
        raise DriveConnectionException
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

      api_client.authorization.update_token!
      file = drive.files.insert.request_schema.new(file_data)

      result = api_client.execute(
        :api_method => drive.files.insert,
        :body_object => file
      )

      if result.status == 200
        result
      else
        raise DriveConnectionException
      end
    end

    def delete_doc(document_id)
      api_client.authorization.update_token!
      result = api_client.execute(
        :api_method => drive.files.delete,
        :parameters => { :fileId => document_id })
      if result.error? && !result.error_message.include?('File not found')
        raise DriveConnectionException
      end
    end

    def acl_remove(document_id, users)
      api_client.authorization.update_token!
      users.each do |user_id|
        next if user_id.blank?
        result = api_client.execute(
          :api_method => drive.permissions.delete,
          :parameters => {
            :fileId => document_id,
            :permissionId => user_id })
        if result.error?
          raise DriveConnectionException, result
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
    def acl_add(document_id, users, domain = nil)
      # TODO: support domain
      api_client.authorization.update_token!
      users.each do |user_id|
        new_permission = drive.permissions.insert.request_schema.new({
           :id => user_id,
           :type => 'user',
           :role => 'writer'
        })
        result = api_client.execute(
          :api_method => drive.permissions.insert,
          :body_object => new_permission,
          :parameters => { :fileId => document_id }
        )
        if result.error?
          raise DriveConnectionException
        end
      end
    end

    def verify_access_token
      api_client.authorization.update_token!
      api_client.execute(:api_method => drive.about.get).status == 200
    end

    def self.config_check(settings)
      raise DriveConnectionException("No config check")
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

    def list(extensions)
      folderize_list(api_client.execute!(:api_method => drive.files.list, :parameters => {:maxResults => 0}).data.to_hash, extensions)
    end


    def folderize_list(documents, extensions)
      root = GoogleDocs::DriveFolder.new('/')
      folders = {nil => root}

      documents['items'].each do |doc_entry|
        entry = GoogleDocs::DriveEntry.new(doc_entry, extensions)
        if folders.has_key?(entry.folder)
          folder = folders[entry.folder]
        else
          folder = GoogleDocs::DriveFolder.new(get_folder_name_by_id(documents['items'], entry.folder))
          root.add_folder folder
          folders[entry.folder] = folder
        end
        folder.add_file(entry) unless doc_entry['mimeType'] && doc_entry['mimeType'] == 'application/vnd.google-apps.folder'
      end

      if extensions && extensions.length > 0
        root = root.select { |e| extensions.include?(e.extension) }
      end

      root.select { |e| !e.in_trash? }
    end

    def get_folder_name_by_id(entries, folder_id)
      elements = entries.select do |entry|
        entry['id'] == folder_id
      end
      elements.first ? elements.first['title'] : 'Unknown Folder'
    end

    def api_client
      return nil if GoogleDocs::DriveConnection.config.nil?
      @api_client ||= GoogleDrive::Client.create(GoogleDocs::DriveConnection.config, @refresh_token, @access_token)
    end

    def drive
      api_client.discovered_api('drive', 'v2')
    end

  end
end

