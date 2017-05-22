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

class CreateProgresses < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_table :progresses do |t|
      t.integer :context_id, :limit => 8
      t.string :context_type
      t.integer :user_id, :limit => 8
      t.string :tag, :null => false
      t.float :completion
      t.string :delayed_job_id
      t.string :workflow_state
      t.datetime :created_at
      t.datetime :updated_at
      t.text :message
    end
    add_index :progresses, [:context_id, :context_type], :name => "index_progresses_on_context_id_and_context_type"
    add_index :progresses, [:user_id], :name => "index_progresses_on_user_id"
  end

  def self.down
    drop_table :progresses
  end
end
