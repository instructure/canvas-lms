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

class UpdateCollectionItemColumns < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    rename_column :collection_items, :description, :user_comment

    add_column :collection_item_datas, :title, :string
    add_column :collection_item_datas, :description, :text
  end

  def self.down
    rename_column :collection_items, :user_comment, :description

    remove_column :collection_item_datas, :title, :string
    remove_column :collection_item_datas, :description, :text
  end
end
