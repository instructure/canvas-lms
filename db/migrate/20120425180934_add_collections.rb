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

class AddCollections < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_table :collections do |t|
      t.string :name
      t.string :visibility, :default => "private"

      t.string :context_type
      t.integer :context_id, :limit => 8

      t.string :workflow_state

      t.timestamps null: true
    end
    add_index :collections, [:context_id, :context_type, :workflow_state, :visibility], :name => "index_collections_for_finding"

    create_table :collection_items do |t|
      t.integer :collection_item_data_id, :limit => 8
      t.integer :collection_id, :limit => 8

      t.string :workflow_state

      t.text :description

      t.integer :image_attachment_id, :limit => 8
      t.text :image_url

      t.timestamps null: true
    end
    add_index :collection_items, [:collection_id, :workflow_state]
    add_index :collection_items, [:collection_item_data_id, :workflow_state], :name => "index_collection_items_on_data_id"

    create_table :collection_item_datas do |t|
      t.string :item_type

      t.text :link_url

      t.integer :root_item_id, :limit => 8

      t.integer :post_count, :default => 0
      t.integer :upvote_count, :default => 0

      t.timestamps null: true
    end

    create_table :collection_item_upvotes do |t|
      t.integer :collection_item_data_id, :limit => 8
      t.integer :user_id, :limit => 8

      t.timestamps null: true
    end
    add_index :collection_item_upvotes, [:collection_item_data_id, :user_id], :unique => true, :name => "index_collection_item_upvotes_join"
  end

  def self.down
    drop_table :collection_item_upvotes
    drop_table :collection_item_datas
    drop_table :collection_items
    drop_table :collections
  end
end
