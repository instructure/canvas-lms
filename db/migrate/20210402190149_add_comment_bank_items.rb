# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

class AddCommentBankItems < ActiveRecord::Migration[6.0]
  tag :predeploy

  def up
    create_table :comment_bank_items do |t|
      t.references :course, index: false, null: false, foreign_key: true
      t.references :root_account, foreign_key: { to_table: :accounts }, null: false
      t.references :user, null: false, foreign_key: true, index: false
      t.text :comment, null: false
      t.timestamps null: false
      t.string :workflow_state, null: false, default: "active"
      t.index [:root_account_id, :id],
              unique: true,
              name: "index_comment_bank_items_replica_identity"
    end

    set_replica_identity(:comment_bank_items, :index_comment_bank_items_replica_identity)

    add_index :comment_bank_items,
              [:course_id, :user_id],
              name: "index_comment_bank_items_on_course_and_user",
              where: "workflow_state <> 'deleted'"
  end

  def down
    drop_table :comment_bank_items
  end
end
