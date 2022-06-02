# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

class AddOutcomeFriendlyDescription < ActiveRecord::Migration[5.2]
  tag :predeploy

  def change
    create_table :outcome_friendly_descriptions do |t|
      t.string :context_type, null: false, limit: 255
      t.integer :context_id, null: false, limit: 8
      t.string :workflow_state, null: false, default: "active"
      t.references :root_account, index: true, foreign_key: { to_table: :accounts }
      t.string :description, null: false, limit: 255
      t.timestamps null: false
      t.references :learning_outcome, foreign_key: true, index: true, null: false
    end

    add_index :outcome_friendly_descriptions, %i[context_type context_id learning_outcome_id], unique: true, name: "index_outcome_friendly_description_on_context_and_outcome"
  end
end
