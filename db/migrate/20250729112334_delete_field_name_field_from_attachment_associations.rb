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
class DeleteFieldNameFieldFromAttachmentAssociations < ActiveRecord::Migration[7.1]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    remove_column :attachment_associations, :field_name, if_exists: true # rubocop:disable Migration/RemoveColumn
    begin
      drop_enum :enum_attachment_associations_field_name, if_exists: true
    rescue ActiveRecord::StatementInvalid => e
      # ignore; some other shard is still using this enum and will drop it later
      raise unless e.cause.is_a?(PG::DependentObjectsStillExist)
    end
  end
end
