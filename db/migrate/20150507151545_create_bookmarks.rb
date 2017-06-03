#
# Copyright (C) 2015 - present Instructure, Inc.
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

class CreateBookmarks < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    create_table :bookmarks_bookmarks do |t|
      t.integer :user_id, limit: 8, null: false
      t.string :name, null: false
      t.string :url, null: false
      t.integer :position
      t.text :json
    end

    add_foreign_key :bookmarks_bookmarks, :users
    add_index :bookmarks_bookmarks, :user_id
  end

  def down
    drop_table :bookmarks_bookmarks
  end
end
