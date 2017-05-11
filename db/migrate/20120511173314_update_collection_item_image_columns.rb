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

class UpdateCollectionItemImageColumns < ActiveRecord::Migration[4.2]
  tag :predeploy

  # rubocop:disable Migration/RemoveColumn
  def self.up
    add_column :collection_item_datas, :image_pending, :boolean
    add_column :collection_item_datas, :image_attachment_id, :integer, :limit => 8
    add_column :collection_item_datas, :image_url, :text
    add_column :collection_items, :user_id, :integer, :limit => 8
    remove_column :collection_items, :image_attachment_id
    remove_column :collection_items, :image_url

    add_foreign_key :collection_items, :users
    add_foreign_key :collection_items, :collections
  end

  def self.down
    remove_column :collection_item_datas, :image_pending
    remove_column :collection_item_datas, :image_attachment_id
    remove_column :collection_item_datas, :image_url
    remove_column :collection_items, :user_id
    add_column :collection_items, :image_attachment_id, :integer, :limit => 8
    add_column :collection_items, :image_url, :text
  end
end
