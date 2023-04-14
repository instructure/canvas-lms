# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

class SwitchToPg12CollationIndexes < ActiveRecord::Migration[5.2]
  tag :predeploy
  disable_ddl_transaction!

  def up
    if connection.index_name_exists?(:users, :index_users_on_sortable_name) &&
       !connection.index_name_exists?(:users, :index_users_on_sortable_name_old2)
      rename_index :users, :index_users_on_sortable_name, :index_users_on_sortable_name_old2
    end
    if connection.index_name_exists?(:attachments, :index_attachments_on_folder_id_and_file_state_and_display_name) &&
       !connection.index_name_exists?(:attachments, :index_attachments_on_fi_and_fs_and_dn_temp)
      rename_index :attachments, :index_attachments_on_folder_id_and_file_state_and_display_name, :index_attachments_on_fi_and_fs_and_dn_temp
    end

    add_index :users, "#{User.best_unicode_collation_key("sortable_name")}, id",
              algorithm: :concurrently, name: :index_users_on_sortable_name, if_not_exists: true

    add_index :attachments, "folder_id, file_state, #{Attachment.best_unicode_collation_key("display_name")}",
              algorithm: :concurrently, name: :index_attachments_on_folder_id_and_file_state_and_display_name,
              where: "folder_id IS NOT NULL", if_not_exists: true
  end
end
