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

class CreateContentParticipations < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_table "content_participations" do |t|
      t.string "content_type"
      t.integer "content_id", :limit => 8
      t.integer "user_id", :limit => 8
      t.string "workflow_state"
    end

    add_index "content_participations", ["content_id", "content_type", "user_id"], :name => "index_content_participations_uniquely", :unique => true
  end

  def self.down
    drop_table "content_participations"
  end
end
