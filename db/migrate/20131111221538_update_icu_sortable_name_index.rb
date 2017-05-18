#
# Copyright (C) 2013 - present Instructure, Inc.
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

class UpdateIcuSortableNameIndex < ActiveRecord::Migration[4.2]
  tag :predeploy

  disable_ddl_transaction!

  def self.up
    if connection.adapter_name == "PostgreSQL" && collkey = connection.extension_installed?(:pg_collkey)
      concurrently = "CONCURRENTLY" if connection.open_transactions == 0
      rename_index :users, 'index_users_on_sortable_name', 'index_users_on_sortable_name_old'
      rename_index :attachments, 'index_attachments_on_folder_id_and_file_state_and_display_name', 'index_attachments_on_folder_id_and_file_state_and_display_name2'
      execute("CREATE INDEX #{concurrently} index_users_on_sortable_name ON #{User.quoted_table_name} (#{collkey}.collkey(sortable_name, 'root', false, 0, true))")
      execute("CREATE INDEX #{concurrently} index_attachments_on_folder_id_and_file_state_and_display_name
        ON #{Attachment.quoted_table_name} (folder_id, file_state,
                        #{collkey}.collkey(display_name, 'root', false, 0, true))
        WHERE folder_id IS NOT NULL")
    end
  end

  def self.down
    if connection.adapter_name == "PostgreSQL" &&
       connection.select_value("SELECT COUNT(*) FROM pg_proc WHERE proname='collkey'").to_i != 0

      remove_index "users", :name => "index_users_on_sortable_name"
      remove_index "attachments", :name => "index_attachments_on_folder_id_and_file_state_and_display_name"

      rename_index :users, 'index_users_on_sortable_name_old', 'index_users_on_sortable_name'
      rename_index :attachments, 'index_attachments_on_folder_id_and_file_state_and_display_name2', 'index_attachments_on_folder_id_and_file_state_and_display_name'
    end
  end
end
