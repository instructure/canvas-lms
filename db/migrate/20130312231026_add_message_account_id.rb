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

class AddMessageAccountId < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def self.up
    add_column :messages, :root_account_id, :integer, :limit => 8
    add_column :delayed_messages, :root_account_id, :integer, :limit => 8

    add_index :messages, :root_account_id, :algorithm => :concurrently
    add_index :delayed_messages, [:communication_channel_id, :root_account_id, :workflow_state, :send_at], :algorithm => :concurrently, :name => "ccid_raid_ws_sa"
    remove_index :delayed_messages, :name => "ccid_ws_sa"
  end

  def self.down
    add_index :delayed_messages, [:communication_channel_id, :workflow_state, :send_at], :algorithm => :concurrently, :name => "ccid_ws_sa"
    remove_index :delayed_messages, :name => "ccid_raid_ws_sa"
    remove_index :messages, :column => :root_account_id

    remove_column :messages, :root_account_id
    remove_column :delayed_messages, :root_account_id
  end
end
