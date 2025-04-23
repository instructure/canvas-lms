# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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
class AddFieldNameToAttachmentAssociations < ActiveRecord::Migration[7.1]
  tag :predeploy

  def change
    create_enum :enum_attachment_associations_field_name, ["syllabus_body"]
    add_column :attachment_associations, :field_name, :enum, enum_type: "#{Shard.current.name}.enum_attachment_associations_field_name", null: true, default: nil
  end
end
