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

class Conversations < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_table "conversations" do |t|
      t.string "private_hash" # for quick lookups so we know whether or not we need to create a new one
    end
    add_index "conversations", ["private_hash"], :unique => true

    create_table "conversation_participants" do |t|
      t.integer  "conversation_id", :limit => 8
      t.integer  "user_id", :limit => 8
      t.datetime "last_message_at"
      t.boolean  "subscribed", :default => true
      t.string   "workflow_state"
    end
    add_index "conversation_participants", ["conversation_id"]
    add_index "conversation_participants", ["user_id", "last_message_at"]

    create_table "conversation_messages" do |t|
      t.integer  "conversation_id", :limit => 8
      t.integer  "author_id", :limit => 8
      t.datetime "created_at"
      t.boolean  "generated"
      t.text     "body"
    end
    add_index "conversation_messages", ["conversation_id", "created_at"]

    create_table "conversation_message_participants" do |t|
      t.integer  "conversation_message_id", :limit => 8
      t.integer  "conversation_participant_id", :limit => 8
    end
  end

  def self.down
    drop_table "conversations"
    drop_table "conversation_participants"
    drop_table "conversation_messages"
    drop_table "conversation_message_participants"
  end
end
