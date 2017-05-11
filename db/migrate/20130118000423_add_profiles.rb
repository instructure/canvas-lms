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

class AddProfiles < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_table :profiles do |t|
      t.integer  :root_account_id, :limit => 8
      t.string   :context_type
      t.integer  :context_id, :limit => 8
      t.string   :title
      t.string   :path
      t.text     :description
      t.text     :data
      t.string   :visibility # public|private
      t.integer  :position
    end
    add_foreign_key :profiles, :accounts, :column => 'root_account_id'
    add_index :profiles, [:root_account_id, :path], :unique => true
    add_index :profiles, [:context_type, :context_id], :unique => true
  end

  def self.down
    drop_table :profiles
  end
end
