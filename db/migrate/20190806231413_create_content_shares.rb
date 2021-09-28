# frozen_string_literal: true

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

class CreateContentShares < ActiveRecord::Migration[5.2]
  tag :predeploy

  def change
    create_table :content_shares do |t|
      t.string :name, limit: 255, null: false
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.integer :user_id, limit: 8, null: false
      t.integer :content_export_id, limit: 8, null: false
      t.integer :sender_id, limit: 8
      t.string :read_state, limit: 255, null: false
    end

    add_foreign_key :content_shares, :users
    add_foreign_key :content_shares, :users, column: :sender_id
    add_index :content_shares, [:user_id, :content_export_id, :sender_id],
      unique: true,
      name: 'index_content_shares_on_user_and_content_export_and_sender_ids'
  end
end
