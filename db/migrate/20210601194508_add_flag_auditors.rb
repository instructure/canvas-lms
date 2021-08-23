# frozen_string_literal: true

# Copyright (C) 2021 - present Instructure, Inc.
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

class AddFlagAuditors < ActiveRecord::Migration[6.0]
  tag :predeploy

  def up
    create_table :auditor_feature_flag_records do |t|
      t.string :uuid, null: false
      t.bigint :feature_flag_id, null: false
      t.bigint :root_account_id, null: false
      t.string :context_type
      t.bigint :context_id
      t.string :feature_name
      t.string :event_type, null: false
      t.string :state_before, null: false
      t.string :state_after, null: false
      t.string :request_id, null: false
      t.bigint :user_id, null: false
      t.datetime :created_at, null: false
    end
    add_index :auditor_feature_flag_records, :uuid
    add_index :auditor_feature_flag_records, :feature_flag_id
    add_index :auditor_feature_flag_records, :root_account_id
    add_foreign_key :auditor_feature_flag_records, :accounts, column: :root_account_id
  end

  def down
    drop_table :auditor_feature_flag_records
  end
end
