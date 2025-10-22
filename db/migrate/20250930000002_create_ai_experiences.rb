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

class CreateAiExperiences < ActiveRecord::Migration[7.2]
  tag :predeploy

  def up
    create_table :ai_experiences do |t|
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false
      t.references :account, foreign_key: { to_table: :accounts }, null: false
      t.references :course, null: false, foreign_key: true, index: false

      t.string :title, null: false, limit: 255
      t.text :description, limit: 65_536
      t.text :facts, null: false, limit: 65_536
      t.text :learning_objective, limit: 65_536
      t.text :scenario, limit: 65_536
      t.string :workflow_state, null: false, default: "unpublished", limit: 255

      t.timestamps
      t.replica_identity_index

      t.index [:root_account_id, :workflow_state]
      t.index [:course_id, :workflow_state]
    end
  end
end
