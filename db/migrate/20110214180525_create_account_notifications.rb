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

class CreateAccountNotifications < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_table :account_notifications do |t|
      t.string :subject
      t.string :icon, :default => 'warning'
      t.text :message
      t.integer :account_id, :limit => 8
      t.integer :user_id, :limit => 8
      t.datetime :start_at
      t.datetime :end_at
      t.timestamps null: true
    end
    add_index :account_notifications, [:account_id, :start_at]
  end

  def self.down
    drop_table :account_notifications
  end
end
