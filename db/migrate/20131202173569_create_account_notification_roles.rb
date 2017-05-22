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

class CreateAccountNotificationRoles < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_table :account_notification_roles do |t|
      t.integer :account_notification_id, :limit => 8, :null => false
      t.string :role_type, :null => false
    end
    add_index :account_notification_roles, [:account_notification_id, :role_type], :unique => true, :name => "idx_acount_notification_roles"
    add_foreign_key :account_notification_roles, :account_notifications
  end

  def self.down
    drop_table :account_notification_roles
  end
end
