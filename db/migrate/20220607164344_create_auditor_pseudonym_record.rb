# frozen_string_literal: true

# Copyright (C) 2022 - present Instructure, Inc.
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

class CreateAuditorPseudonymRecord < ActiveRecord::Migration[6.1]
  tag :predeploy

  def change
    create_table :auditor_pseudonym_records do |t|
      t.references :pseudonym, foreign_key: true, null: false
      t.references :root_account, foreign_key: { to_table: :accounts }, null: false
      t.bigint :performing_user_id, null: false
      t.string :action, null: false
      t.string :hostname, null: false
      t.string :pid, null: false
      t.string :uuid, null: false
      t.string :event_type, null: false
      t.string :request_id

      t.datetime :created_at, null: false
    end

    add_index :auditor_pseudonym_records, :uuid
  end
end
