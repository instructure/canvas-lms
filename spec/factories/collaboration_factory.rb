# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

module Factories
  def collaboration_model(opts = {})
    @collaboration = factory_with_protected_attributes(Collaboration, valid_collaboration_attributes.merge(opts))
  end

  def external_tool_collaboration_model(opts = {})
    opts[:data] ||= nil
    opts[:type] ||= "ExternalToolCollaboration"
    @collaboration = factory_with_protected_attributes(ExternalToolCollaboration, valid_collaboration_attributes.merge(opts))
  end

  def google_docs_collaboration_model(opts = {})
    @collaboration = factory_with_protected_attributes(GoogleDocsCollaboration, valid_collaboration_attributes.merge(opts))
  end

  def valid_collaboration_attributes
    {
      collaboration_type: "value for collaboration_type",
      document_id: "document:dc3pjs4r_3hhc6fvcc",
      user_id: User.create!.id,
      context: @course || course_model,
      url: "value for url",
      title: "My Collaboration",
      data: File.read("gems/google_drive/spec/fixtures/google_drive/file_data.json")
    }
  end
end
