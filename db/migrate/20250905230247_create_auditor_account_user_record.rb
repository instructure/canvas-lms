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
#

class CreateAuditorAccountUserRecord < ActiveRecord::Migration[7.2]
  tag :predeploy

  def change
    create_table :auditor_account_user_records do |t|
      t.references :performing_user, foreign_key: { to_table: :users }
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false
      t.references :account_user, foreign_key: true, null: false
      t.string :action, null: false, limit: 64
      t.string :hostname, null: false, limit: 255
      t.string :uuid, null: false, limit: 255, index: true
      t.string :event_type, null: false, limit: 64
      t.string :request_id, limit: 255
      t.datetime :created_at, null: false

      t.replica_identity_index
    end
  end
end
