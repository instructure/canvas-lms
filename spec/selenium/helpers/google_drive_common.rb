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

module GoogleDriveCommon
  def setup_google_drive(add_user_service=true, authorized=true)


    UserService.register(
      :service => "google_drive",
      :token => "token",
      :secret => "secret",
      :user => @user,
      :service_domain => "drive.google.com",
      :service_user_id => "service_user_id",
      :service_user_name => "service_user_name"
    ) if add_user_service

    GoogleDrive::Connection.any_instance.
      stubs(:authorized?).
      returns(authorized)

    data = stub('data', id: 1, to_json: { id: 1 }, alternateLink: 'http://localhost/googleDoc')
    doc = stub('doc', data: data)
    adapter = stub('google_adapter', create_doc: doc, acl_add: nil, acl_remove: nil)
    GoogleDocsCollaboration.any_instance.
        stubs(:google_adapter_for_user).
        returns(adapter)

    GoogleDocsCollaboration.any_instance.
        stubs(:delete_document).
        returns(nil)

  end
end
