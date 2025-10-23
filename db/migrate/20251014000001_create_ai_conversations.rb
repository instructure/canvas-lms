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

class CreateAiConversations < ActiveRecord::Migration[7.2]
  tag :predeploy

  def up
    create_table :ai_conversations do |t|
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false
      t.references :account, foreign_key: { to_table: :accounts }, null: false
      t.references :course, null: false, foreign_key: true, index: true
      t.references :user, null: false, foreign_key: true, index: true
      t.references :ai_experience, null: false, foreign_key: true, index: true

      t.string :llm_conversation_id, null: false, limit: 255
      t.string :workflow_state, null: false, default: "active", limit: 255

      t.timestamps
      t.replica_identity_index

      t.index [:llm_conversation_id], unique: true
      t.check_constraint "workflow_state IN ('active', 'completed', 'deleted')", name: "chk_workflow_state_enum"
    end
  end
end
