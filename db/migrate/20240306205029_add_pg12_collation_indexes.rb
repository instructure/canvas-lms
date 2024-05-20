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

class AddPg12CollationIndexes < ActiveRecord::Migration[7.0]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    unless connection.index_exists?(:users, [:sortable_name, :id], name: "index_users_on_sortable_name")
      if connection.index_name_exists?(:users, :index_users_on_sortable_name)
        if connection.index_name_exists?(:users, :index_users_on_sortable_name_collkey)
          # both indexes exist? probably from a failed migration. just remove the base index and try again
          remove_index :users, name: :index_users_on_sortable_name # rubocop:disable Migration/NonTransactional
        else
          rename_index :users, :index_users_on_sortable_name, :index_users_on_sortable_name_collkey
        end
      end
      add_index :users,
                "(sortable_name COLLATE public.\"und-u-kn-true\"), id",
                name: :index_users_on_sortable_name,
                algorithm: :concurrently,
                if_not_exists: true
    end

    unless connection.index_exists?(:attachments, %i[folder_id file_state display_name], name: "index_attachments_on_folder_id_and_file_state_and_display_name")
      if connection.index_name_exists?(:attachments, :index_attachments_on_folder_id_and_file_state_and_display_name)
        if connection.index_name_exists?(:attachments, :index_attachments_collkey)
          remove_index :attachments, name: :index_attachments_on_folder_id_and_file_state_and_display_name # rubocop:disable Migration/NonTransactional
        else
          rename_index :attachments, :index_attachments_on_folder_id_and_file_state_and_display_name, :index_attachments_collkey
        end
      end
      add_index :attachments,
                "folder_id, file_state, (display_name COLLATE public.\"und-u-kn-true\")",
                name: :index_attachments_on_folder_id_and_file_state_and_display_name,
                where: "folder_id IS NOT NULL",
                algorithm: :concurrently,
                if_not_exists: true
    end
  end

  def down
    if connection.index_name_exists?(:users, :index_users_on_sortable_name_collkey)
      remove_index :users, name: :index_users_on_sortable_name, if_exists: true
      rename_index :users, :index_users_on_sortable_name_collkey, :index_users_on_sortable_name
    end
    if connection.index_name_exists?(:attachments, :index_attachments_collkey)
      remove_index :attachments, name: :index_attachments_on_folder_id_and_file_state_and_display_name, if_exists: true
      rename_index :attachments, :index_attachments_collkey, :index_attachments_on_folder_id_and_file_state_and_display_name
    end
  end
end
