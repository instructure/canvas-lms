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

class CreateContentParticipationCounts < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_table "content_participation_counts" do |t|
      t.string "content_type"
      t.string "context_type"
      t.integer "context_id", :limit => 8
      t.integer "user_id", :limit => 8
      t.integer "unread_count", :default => 0
      t.timestamps null: true
    end

    add_index "content_participation_counts", ["context_id", "context_type", "user_id", "content_type"], :name => "index_content_participation_counts_uniquely", :unique => true
  end

  def self.down
    drop_table "content_participation_counts"
  end
end
