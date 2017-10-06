#
# Copyright (C) 2017 - present Instructure, Inc.
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

class CreateMasterMigrationResults < ActiveRecord::Migration[5.0]
  tag :predeploy

  def change
    create_table :master_courses_migration_results do |t|
      t.integer :master_migration_id, limit: 8, null: false
      t.integer :content_migration_id, limit: 8, null: false
      t.integer :child_subscription_id, limit: 8, null: false
      t.string :import_type, null: false
      t.string :state, null: false
      t.text :results
    end

    add_foreign_key :master_courses_migration_results, :master_courses_master_migrations, column: "master_migration_id"
    add_foreign_key :master_courses_migration_results, :master_courses_child_subscriptions, column: "child_subscription_id"
    add_foreign_key :master_courses_migration_results, :content_migrations

    add_index :master_courses_migration_results, [:master_migration_id, :state],
      :name => "index_mc_migration_results_on_master_mig_id_and_state"
    add_index :master_courses_migration_results, [:master_migration_id, :content_migration_id],
      :unique => true, :name => "index_mc_migration_results_on_master_and_content_migration_ids"
  end
end
