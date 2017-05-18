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

class DropHashtags < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    drop_table :short_message_associations
    drop_table :short_messages
    drop_table :hashtags
    remove_column :courses, :hashtag
  end

  def self.down
    add_column :courses, :hashtag, :string

    create_table "hashtags" do |t|
      t.string   "hashtag"
      t.datetime "refresh_at"
      t.string   "last_result_id"
      t.timestamps
    end

    create_table "short_messages" do |t|
      t.string   "message"
      t.integer  "user_id", :limit => 8
      t.string   "author_name"
      t.timestamps
      t.boolean  "is_public",          :default => false
      t.string   "service_message_id"
      t.string   "service"
      t.string   "service_user_name"
    end

    add_index "short_messages", ["user_id"]

    create_table "short_message_associations" do |t|
      t.integer  "context_id", :limit => 8
      t.string   "context_type"
      t.integer  "short_message_id", :limit => 8
      t.timestamps
    end

    add_index "short_message_associations", ["context_id", "context_type"]
    add_index "short_message_associations", ["short_message_id"]
  end
end
