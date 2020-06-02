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

class CreateConditionalReleaseTables < ActiveRecord::Migration[5.2]
  tag :predeploy

  def change
    create_table :conditional_release_rules do |t|
      t.references :course, foreign_key: true, limit: 8
      t.references :trigger_assignment, foreign_key: { to_table: 'assignments' }, limit: 8
      t.datetime :deleted_at

      t.references :root_account, foreign_key: { to_table: 'accounts' }, limit: 8, null: false,
        index: { name: 'index_cr_rules_on_root_account_id' }
      t.index [:root_account_id, :course_id], where: 'deleted_at IS NULL', name: 'index_cr_rules_on_account_and_course'
      t.timestamps
    end

    create_table :conditional_release_scoring_ranges do |t|
      t.references :rule, foreign_key: { to_table: 'conditional_release_rules' }, limit: 8, index: false, null: false
      t.decimal :lower_bound
      t.decimal :upper_bound
      t.integer :position
      t.datetime :deleted_at
      t.index :rule_id, where: 'deleted_at IS NULL', name: 'index_cr_scoring_ranges_on_rule_id'

      t.references :root_account, foreign_key: { to_table: 'accounts'}, limit: 8, null: false,
        index: { name: 'index_cr_scoring_ranges_on_root_account_id' }
      t.timestamps
    end

    create_table :conditional_release_assignment_sets do |t|
      t.references :scoring_range, foreign_key: { to_table: 'conditional_release_scoring_ranges' }, limit: 8, index: false, null: false
      t.integer :position
      t.datetime :deleted_at
      t.index :scoring_range_id, where: 'deleted_at IS NULL', name: 'index_cr_assignment_sets_on_scoring_range_id'

      t.references :root_account, foreign_key: { to_table: 'accounts'}, limit: 8, null: false,
        index: { name: 'index_cr_assignment_sets_on_root_account_id' }
      t.timestamps
    end

    create_table :conditional_release_assignment_set_associations do |t|
      t.references :assignment_set, foreign_key: {to_table: 'conditional_release_assignment_sets'}, limit: 8, index: false
      t.index :assignment_id, where: 'deleted_at IS NULL', name: 'index_cr_assignment_set_associations_on_set'

      t.references :assignment, foreign_key: true, limit: 8, index: false
      t.integer :position
      t.datetime :deleted_at

      t.index [:assignment_id, :assignment_set_id], unique: true, where: 'deleted_at IS NULL',
        name: 'index_cr_assignment_set_associations_on_assignment_and_set'

      t.references :root_account, foreign_key: { to_table: 'accounts'}, limit: 8, null: false,
        index: { name: 'index_cr_assignment_set_associations_on_root_account_id' }
      t.timestamps
    end

    create_table :conditional_release_assignment_set_actions do |t|
      t.string :action, null: false
      t.string :source, null: false
      t.integer :student_id, null: false, limit: 8
      t.integer :actor_id, null: false, limit: 8
      t.integer :assignment_set_id, limit: 8
      t.datetime :deleted_at
      t.index :assignment_set_id, where: 'deleted_at IS NULL',
        name: 'index_cr_assignment_set_actions_on_assignment_set_id'
      t.index [:assignment_set_id, :student_id, :created_at], order: { created_at: :desc }, where: 'deleted_at IS NULL',
        name: 'index_cr_assignment_set_actions_on_set_and_student'

      t.references :root_account, foreign_key: { to_table: 'accounts'}, limit: 8, null: false,
        index: { name: 'index_cr_assignment_set_actions_on_root_account_id' }
      t.timestamps
    end

    create_table :conditional_release_rule_templates do |t|
      t.string :name
      t.integer :context_id, limit: 8
      t.string :context_type
      t.datetime :deleted_at

      t.references :root_account, foreign_key: { to_table: 'accounts'}, limit: 8, null: false,
        index: { name: 'index_cr_rule_templates_on_root_account_id' }
      t.index [:root_account_id, :context_id, :context_type], where: 'deleted_at IS NULL',
        name: 'index_cr_rule_templates_on_account_and_context'
      t.timestamps
    end

    create_table :conditional_release_scoring_range_templates do |t|
      t.references :rule_template, foreign_key: { to_table: 'conditional_release_rule_templates' }, limit: 8, index: false
      t.decimal :upper_bound
      t.decimal :lower_bound
      t.datetime :deleted_at
      t.index :rule_template_id, where: 'deleted_at IS NULL', name: 'index_cr_scoring_range_templates_on_rule_template_id'

      t.references :root_account, foreign_key: { to_table: 'accounts'}, limit: 8, null: false,
        index: { name: 'index_cr_scoring_range_templates_on_root_account_id' }
      t.timestamps
    end
  end
end
