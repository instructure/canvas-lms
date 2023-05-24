# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

class DropOldCollationKeyIndexes < ActiveRecord::Migration[5.0]
  tag :postdeploy

  disable_ddl_transaction!

  def up
    return unless connection.extension(:pg_collkey)

    if connection.index_name_exists?(:users, :index_users_on_sortable_name_old)
      remove_index :users, name: :index_users_on_sortable_name_old
    end

    if connection.index_name_exists?(:attachments, :index_attachments_on_folder_id_and_file_state_and_display_name1)
      remove_index :attachments, name: :index_attachments_on_folder_id_and_file_state_and_display_name1
    end
  end

  def down
    collkey = connection.extension(:pg_collkey)&.schema
    return unless collkey

    add_index :attachments,
              "folder_id, file_state, #{collkey}.collkey(display_name, 'root', false, 0, true)",
              algorithm: :concurrently,
              name: :index_attachments_on_folder_id_and_file_state_and_display_name1,
              where: "folder_id IS NOT NULL"

    add_index :users,
              "#{collkey}.collkey(sortable_name, 'root', false, 0, true)",
              algorithm: :concurrently,
              name: :index_users_on_sortable_name_old
  end
end
