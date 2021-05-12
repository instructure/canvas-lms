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

class AddUserIndexCommentBankItems < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!
  tag :predeploy

  def change
    remove_index :comment_bank_items,
                 algorithm: :concurrently,
                 column: [:course_id, :user_id],
                 where: "workflow_state <> 'deleted'",
                 name: :index_comment_bank_items_on_course_and_user,
                 if_exists: true

    add_index :comment_bank_items,
              :user_id,
              algorithm: :concurrently,
              name: 'index_active_comment_bank_items_on_user',
              where: "workflow_state <> 'deleted'",
              if_not_exists: true

    add_index :comment_bank_items,
              :course_id,
              algorithm: :concurrently,
              if_not_exists: true

    add_index :comment_bank_items,
              :user_id,
              algorithm: :concurrently,
              if_not_exists: true
  end
end
