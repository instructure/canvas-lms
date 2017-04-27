#
# Copyright (C) 2011 - present Instructure, Inc.
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

class AddZipFileImports < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_table :zip_file_imports do |t|
      t.string    :workflow_state
      t.datetime  :created_at
      t.datetime  :updated_at
      t.integer   :context_id,      :limit => 8
      t.string    :context_type
      t.integer   :attachment_id,   :limit => 8
      t.integer   :folder_id,       :limit => 8
      t.float     :progress
      t.text      :data
    end
  end

  def self.down
    drop_table :zip_file_imports
  end
end
