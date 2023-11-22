# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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
class CreateRubricCriteria < ActiveRecord::Migration[7.0]
  tag :predeploy
  def change
    create_table :rubric_criteria do |t|
      t.references :rubric, null: false, foreign_key: { to_table: :rubrics }, index: true
      t.references :root_account, null: false, foreign_key: { to_table: :accounts }, index: false
      t.text :description, null: true
      t.text :long_description, null: true
      t.integer :order, null: false
      t.decimal :points, null: false
      t.boolean :criterion_use_range, null: false, default: false
      t.references :learning_outcome, null: true, foreign_key: { to_table: :learning_outcomes }, index: true
      t.decimal :mastery_points, null: true
      t.boolean :ignore_for_scoring, null: false, default: false
      t.string :workflow_state, null: false, default: "active", limit: 255
      t.references :created_by, null: false, foreign_key: { to_table: :users }, index: true
      t.references :deleted_by, null: true, foreign_key: { to_table: :users }, index: true
      t.timestamps
    end
  end
end
