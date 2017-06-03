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

class RemoveMultipleRootFolders < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    DataFixup::RemoveMultipleRootFolders.run
    if connection.adapter_name =~ /\Apostgresql/i
      add_index :folders, [:context_id, :context_type], :unique => true, :name => 'index_folders_on_context_id_and_context_type_for_root_folders', :algorithm => :concurrently, :where => "parent_folder_id IS NULL AND workflow_state<>'deleted'"
    end
  end

  def self.down
    if connection.adapter_name =~ /\Apostgresql/i
      remove_index :folders, name: 'index_folders_on_context_id_and_context_type_for_root_folders'
    end
  end
end
