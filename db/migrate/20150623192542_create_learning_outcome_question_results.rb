#
# Copyright (C) 2015 - present Instructure, Inc.
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

class CreateLearningOutcomeQuestionResults < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    create_table :learning_outcome_question_results do |t|
      t.integer :learning_outcome_result_id, limit: 8
      t.integer :learning_outcome_id, limit: 8
      t.integer :context_id, limit: 8
      t.integer :associated_asset_id, limit: 8
      t.string :associated_asset_type
      t.string :context_type
      t.string :context_code

      t.float :score
      t.float :possible
      t.boolean :mastery
      t.float :percent
      t.integer :attempt
      t.text :title

      t.float :original_score
      t.float :original_possible
      t.boolean :original_mastery

      t.datetime :assessed_at
      t.datetime :created_at
      t.datetime :updated_at
      t.datetime :submitted_at
    end

    add_index "learning_outcome_question_results", [:learning_outcome_id], name: "index_learning_outcome_question_results_on_learning_outcome_id"
    add_index "learning_outcome_question_results", [:learning_outcome_result_id], name: "index_LOQR_on_learning_outcome_result_id"
  end

  def down
    drop_table :learning_outcome_question_results
    remove_index :learning_outcome_question_results, [:learning_outcome_id]
    remove_index :learning_outcome_question_results, [:learning_outcome_result_id]
  end
end
