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

class DropOldSortableNameIndex < ActiveRecord::Migration[4.2]
  tag :postdeploy

  disable_ddl_transaction!

  def self.up
    if connection.adapter_name == "PostgreSQL" && connection.extension_installed?(:pg_collkey)
      remove_index "users", :name => "index_users_on_sortable_name_old"
      remove_index "attachments", :name => "index_attachments_on_folder_id_and_file_state_and_display_name2"
    end
  end

  def self.down
    if collkey = connection.extension_installed?(:pg_collkey)
      execute <<-SQL
        CREATE INDEX CONCURRENTLY index_users_on_sortable_name_old
        ON #{User.quoted_table_name} (#{collkey}.collkey(sortable_name, 'root', true, 2, true));

        CREATE INDEX CONCURRENTLY
        index_attachments_on_folder_id_and_file_state_and_display_name2
        ON #{Attachment.quoted_table_name} (folder_id, file_state,
                        #{collkey}.collkey(display_name, 'root', true, 2, true))
        WHERE folder_id IS NOT NULL")
      SQL
    end
  end
end
