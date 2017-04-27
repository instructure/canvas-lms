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

class FixAttachmentSortingIndexes < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    if connection.adapter_name == 'PostgreSQL' && connection.select_value("SELECT 1 FROM pg_index WHERE indexrelid='#{connection.quote_table_name('index_attachments_on_folder_id_and_file_state_and_position')}'::regclass AND indpred IS NOT NULL")
      rename_index :attachments, 'index_attachments_on_folder_id_and_file_state_and_position', 'index_attachments_on_folder_id_and_file_state_and_position2'
      add_index :attachments, [:folder_id, :file_state, :position], :algorithm => :concurrently
      remove_index :attachments, name: 'index_attachments_on_folder_id_and_file_state_and_position2'
    end
  end
end
