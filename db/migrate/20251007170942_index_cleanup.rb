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

class IndexCleanup < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!
  tag :predeploy

  def change
    remove_index :originality_reports, :workflow_state, if_exists: true, concurrently: true
    remove_index :originality_reports, :originality_report_attachment_id, if_exists: true, concurrently: true
    remove_index :learning_outcome_question_results, :learning_outcome_id, if_exists: true, concurrently: true
    remove_index :learning_outcome_groups, :vendor_guid_2, if_exists: true, concurrently: true
    remove_index :observer_alerts, :workflow_state, if_exists: true, concurrently: true
    remove_index :notification_policy_overrides, :notification_id, if_exists: true, concurrently: true
    remove_index :learning_outcomes, :root_account_ids, if_exists: true, concurrently: true
    remove_index :outcome_imports, :learning_outcome_group_id, if_exists: true, concurrently: true
    remove_index :quiz_migration_alerts, [:migration_type, :migration_id], if_exists: true, concurrently: true
    remove_index :lti_product_families, :developer_key_id, if_exists: true, concurrently: true
    remove_index :account_domain_lookups, :name, if_exists: true, concurrently: true
    remove_index :error_reports, :zendesk_ticket_id, if_exists: true, concurrently: true

    drop_table :sessions, if_exists: true do |t|
      t.string :session_id, null: false, limit: 255, index: true
      t.text :data
      t.timestamps precision: nil

      t.index :updated_at
    end

    rename_index :observer_alerts, :index_observer_alerts_on_context, :index_observer_alerts_on_context_type_and_context_id if index_exists?(:index_observer_alerts_on_context)
  end
end
