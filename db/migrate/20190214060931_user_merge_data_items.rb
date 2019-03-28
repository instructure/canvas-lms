#
# Copyright (C) 2019 - present Instructure, Inc.
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

class UserMergeDataItems < ActiveRecord::Migration[5.1]
  tag :predeploy

  def change
    create_table :user_merge_data_items do |t|
      t.references :user_merge_data, limit: 8, foreign_key: true, index: true, null: false
      t.references :user, limit: 8, foreign_key: true, index: true, null: false
      t.string :item_type, null: false, limit: 255
      t.text :item, null: false
    end
  end
end
