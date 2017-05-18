#
# Copyright (C) 2016 - present Instructure, Inc.
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

class DropInboxItems < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    remove_column :users, :unread_inbox_items_count
    drop_table :inbox_items
  end

  def down
    add_column :users, :unread_inbox_items_count, :integer

    create_table "inbox_items" do |t|
      t.integer  "user_id", :limit => 8
      t.integer  "sender_id", :limit => 8
      t.integer  "asset_id", :limit => 8
      t.string   "subject"
      t.string   "body_teaser"
      t.string   "asset_type"
      t.string   "workflow_state"
      t.boolean  "sender"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "context_code"
    end
  end
end
