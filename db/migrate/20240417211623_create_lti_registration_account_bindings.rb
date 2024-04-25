# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

class CreateLtiRegistrationAccountBindings < ActiveRecord::Migration[7.0]
  tag :predeploy

  def change
    create_table :lti_registration_account_bindings do |t|
      t.belongs_to :registration, null: false, foreign_key: { to_table: :lti_registrations }
      t.belongs_to :account, null: false, foreign_key: true
      t.belongs_to :created_by, foreign_key: { to_table: :users }
      t.belongs_to :updated_by, foreign_key: { to_table: :users }
      t.string :workflow_state, null: false, default: "off"

      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false
      t.references :developer_key_account_binding, foreign_key: true, index: { name: "index_lrab_on_developer_key_account_binding_id" }
      t.replica_identity_index
      t.timestamps

      t.index %i[account_id registration_id], name: "index_lti_reg_bindings_on_account_id_and_registration_id", unique: true
    end
  end
end
