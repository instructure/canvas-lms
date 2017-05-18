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

class AddUserObservers < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!
  tag :predeploy

  def self.up
    create_table :user_observers do |t|
      t.integer :user_id, :limit => 8, :null => false
      t.integer :observer_id, :limit => 8, :null => false
    end
    add_index :user_observers, [:user_id, :observer_id], :unique => true
    add_index :user_observers, :observer_id

    # User#move_to_user already needed this, and now we do a second query there
    add_index :enrollments, [:associated_user_id], :algorithm => :concurrently, :where => "associated_user_id IS NOT NULL"
  end

  def self.down
    drop_table :user_observers
    remove_index :enrollments, :name => "index_enrollments_on_associated_user_id"
  end
end
