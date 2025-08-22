# frozen_string_literal: true

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

class CreateLtiRegistrationHistoryEntries < ActiveRecord::Migration[7.2]
  tag :predeploy

  def change
    create_table :lti_registration_history_entries do |t|
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false
      t.references :lti_registration, foreign_key: true, null: false
      t.references :created_by, foreign_key: { to_table: :users }, null: false
      t.jsonb :diff, null: false
      t.text :update_type, null: false
      t.text :comment

      t.timestamps
      t.replica_identity_index
    end
  end
end
