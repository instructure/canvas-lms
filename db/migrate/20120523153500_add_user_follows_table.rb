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

class AddUserFollowsTable < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_table :user_follows do |t|
      t.integer :following_user_id, :limit => 8
      t.string  :followed_item_type
      t.integer :followed_item_id, :limit => 8

      t.timestamps null: true
    end
    # unique index of things a user is following, searchable by thing type
    add_index :user_follows, [:following_user_id, :followed_item_type, :followed_item_id], :unique => true, :name => "index_user_follows_unique"
    # the reverse index -- users who are following this thing
    add_index :user_follows, [:followed_item_id, :followed_item_type], :name => "index_user_follows_inverse"
  end

  def self.down
    drop_table :user_follows
  end
end
