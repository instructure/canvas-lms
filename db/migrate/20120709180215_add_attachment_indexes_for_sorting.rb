#
# Copyright (C) 2012 - present Instructure, Inc.
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

class AddAttachmentIndexesForSorting < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def self.up
    if connection.adapter_name == 'PostgreSQL'
      concurrently = " CONCURRENTLY" if connection.open_transactions == 0
      if collkey = connection.extension_installed?(:pg_collkey)
        execute("CREATE INDEX#{concurrently} index_attachments_on_folder_id_and_file_state_and_display_name ON #{Attachment.quoted_table_name} (folder_id, file_state, #{collkey}.collkey(display_name, 'root', true, 2, true)) WHERE folder_id IS NOT NULL")
      else
        execute("CREATE INDEX#{concurrently} index_attachments_on_folder_id_and_file_state_and_display_name ON #{Attachment.quoted_table_name} (folder_id, file_state, CAST(LOWER(replace(display_name, '\\', '\\\\')) AS bytea)) WHERE folder_id IS NOT NULL")
      end
    else
      add_index :attachments, [:folder_id, :file_state, :display_name], :length => { :display_name => 20 }
    end
    add_index :attachments, [:folder_id, :file_state, :position], :algorithm => :concurrently

    remove_index :attachments, :folder_id
  end

  def self.down
    add_index :attachments, :folder_id, algorithm: :concurrently
    remove_index :attachments, "index_attachments_on_folder_id_and_file_state_and_display_name"
    remove_index :attachments, "index_attachments_on_folder_id_and_file_state_and_position"
  end
end
