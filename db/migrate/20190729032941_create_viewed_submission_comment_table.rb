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

class CreateViewedSubmissionCommentTable < ActiveRecord::Migration[5.1]
  tag :predeploy
  disable_ddl_transaction!

  def change
    create_table :viewed_submission_comments do |t|
      t.integer :user_id, limit: 8, null: false
      t.integer :submission_comment_id, limit: 8, null: false
      t.datetime :viewed_at, null: false
    end

    add_foreign_key :viewed_submission_comments, :submission_comments
    add_foreign_key :viewed_submission_comments, :users
    add_index :viewed_submission_comments, [:user_id, :submission_comment_id], name:'index_viewed_submission_comments_user_comment', unique: true
  end
end
