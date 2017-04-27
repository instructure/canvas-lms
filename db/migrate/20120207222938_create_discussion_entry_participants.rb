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

class CreateDiscussionEntryParticipants < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_table "discussion_entry_participants" do |t|
      t.integer "discussion_entry_id", :limit => 8
      t.integer "user_id", :limit => 8
      t.string "workflow_state"
    end

    create_table "discussion_topic_participants" do |t|
      t.integer "discussion_topic_id", :limit => 8
      t.integer "user_id", :limit => 8
      t.integer "unread_entry_count", :default => 0
      t.string "workflow_state"
    end

    add_index "discussion_entry_participants", ["discussion_entry_id", "user_id"], :name => "index_entry_participant_on_entry_id_and_user_id", :unique => true
    add_index "discussion_topic_participants", ["discussion_topic_id", "user_id"], :name => "index_topic_participant_on_topic_id_and_user_id", :unique => true
  end

  def self.down
    drop_table "discussion_entry_participants"
    drop_table "discussion_topic_participants"
  end
end
