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

class AddTableForLLMResponses < ActiveRecord::Migration[7.2]
  tag :predeploy

  def change
    create_table :llm_responses do |t|
      t.references :associated_assignment, foreign_key: { to_table: :assignments }, null: false
      t.references :user, null: false, foreign_key: true
      t.string :prompt_name, null: false, limit: 255
      t.string :prompt_model_id, null: false, limit: 255
      t.jsonb :prompt_dynamic_content
      t.text :raw_response, null: false
      t.integer :input_tokens, null: false
      t.integer :output_tokens, null: false
      t.float :response_time, null: false

      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false
      t.replica_identity_index

      t.timestamps

      t.index [:prompt_name, :prompt_model_id]
    end
  end
end
