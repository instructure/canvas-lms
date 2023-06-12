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

module GoogleDriveCommon
  def setup_google_drive(add_user_service = true, authorized = true)
    if add_user_service
      UserService.register(
        service: "google_drive",
        token: "token",
        secret: "secret",
        user: @user,
        service_domain: "drive.google.com",
        service_user_id: "service_user_id",
        service_user_name: "service_user_name"
      )
    end

    allow_any_instance_of(GoogleDrive::Connection)
      .to receive(:authorized?)
      .and_return(authorized)

    data = double("data", id: 1, to_json: { id: 1 }, alternateLink: "http://localhost/googleDoc")
    doc = double("doc", data:)
    adapter = double("google_adapter", create_doc: doc, acl_add: nil, acl_remove: nil)
    allow_any_instance_of(GoogleDocsCollaboration)
      .to receive(:google_adapter_for_user)
      .and_return(adapter)

    allow_any_instance_of(GoogleDocsCollaboration)
      .to receive(:delete_document)
      .and_return(nil)
  end
end
