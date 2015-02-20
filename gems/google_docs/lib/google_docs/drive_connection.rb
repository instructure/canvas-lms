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
      :google_drive
    end

    def download(document_id)
      response = api_client.execute!(
        :api_method => drive.files.get,
        :parameters => { :fileId => document_id }
      )

      file = response.data
      file_info = get_file_info(file)
      result = api_client.execute(:uri => file_info[:url])
      if result.status == 200

        # hack to make it seem like the old object
        result.define_singleton_method(:content_type) do
          result.headers['Content-Type']
        end

        # TODO: get extension from response header
        [result, file.title, file_info[:ext]]
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
      return api_client.execute(:api_method => drive.about.get).status == 200
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
      documents = api_client.execute!(:api_method => drive.files.list).data.to_hash
      {
        :name => '/',
        :folders => [],
        :files => documents['items'].map do |doc|
          doc_info = get_file_info(doc)

          if extensions.include?(doc_info[:ext])
            {
              :name => doc['title'],
              :document_id => doc['id'],
              :extension => doc_info[:ext],
              :alternate_url => {
                :href => doc_info[:url]
              }
            }
          end
        end.compact!
      }
    end

    def api_client
      return nil if GoogleDocs::DriveConnection.config.nil?
      @api_client ||= GoogleDrive::Client.create(GoogleDocs::DriveConnection.config, @refresh_token, @access_token)
    end

    def drive
      api_client.discovered_api('drive', 'v2')
    end

    def get_file_info(file)
      file_ext = {
        ".docx" => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        ".xlsx" => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ".pdf" => 'application/pdf',
      }

      e = file_ext.find {|extension, mime_type| file['exportLinks'] && file['exportLinks'][mime_type] }
      if e.present?
        {
          url: file['exportLinks'][e.last],
          ext: e.first
        }
      else
        {
          url: file['downloadUrl'],
          ext: ".none"
        }
      end
    end
  end
end

