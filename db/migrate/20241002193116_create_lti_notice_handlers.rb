# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

class CreateLtiNoticeHandlers < ActiveRecord::Migration[7.1]
  tag :predeploy

  def change
    create_table :lti_notice_handlers do |t|
      t.belongs_to :account, null: false, index: false, foreign_key: true
      t.string :notice_type, null: false, limit: 255
      t.string :url, null: false, limit: 4.kilobytes
      t.string :workflow_state, null: false, default: "active", limit: 255
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false
      t.references :context_external_tool, null: false, foreign_key: true

      t.replica_identity_index
      t.timestamps

      t.index %i[account_id context_external_tool_id]
    end
  end
end
