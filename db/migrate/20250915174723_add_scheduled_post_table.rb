# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

class AddScheduledPostTable < ActiveRecord::Migration[7.2]
  tag :predeploy

  def change
    create_table :scheduled_posts do |t|
      t.timestamp :post_comments_at, null: false
      t.timestamp :post_comments_ran_at, null: true
      t.timestamp :post_grades_at, null: false
      t.timestamp :post_grades_ran_at, null: true
      t.references :root_account, null: false, foreign_key: { to_table: :accounts }, index: false
      t.references :post_policy, null: false, foreign_key: { to_table: :post_policies, on_delete: :cascade }, index: { unique: true }
      t.references :assignment, null: false, foreign_key: { to_table: :assignments, on_delete: :cascade }, index: { unique: true }
      t.timestamps
      t.replica_identity_index
    end
  end
end
