# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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
#
class CreatePurgatory < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    create_table :purgatories do |t|
      t.integer :attachment_id, limit: 8, null: false
      t.integer :deleted_by_user_id, limit: 8
      t.timestamps null: false
      t.string :workflow_state, null: false, default: 'active'
      t.string :old_filename, null: false
    end
    add_foreign_key :purgatories, :users, column: :deleted_by_user_id
    add_foreign_key :purgatories, :attachments
    add_index :purgatories, :attachment_id, unique: true
  end
end
