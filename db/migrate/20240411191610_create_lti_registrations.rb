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

class CreateLtiRegistrations < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!
  tag :predeploy

  def change
    create_table :lti_registrations, if_not_exists: true do |t|
      t.boolean :internal_service, null: false, default: false
      t.belongs_to :account, null: false, foreign_key: true
      t.belongs_to :root_account, null: false, foreign_key: { to_table: :accounts }, index: false
      t.belongs_to :created_by, null: false, foreign_key: { to_table: :users }, index: { if_not_exists: true }
      t.belongs_to :updated_by, null: false, foreign_key: { to_table: :users }, index: { if_not_exists: true }
      t.string :name, null: false, index: true, limit: 255
      t.string :admin_nickname, limit: 255
      t.string :vendor, limit: 255

      t.string :workflow_state, default: "active", null: false, limit: 255
      t.replica_identity_index

      t.timestamps
    end

    add_reference :lti_ims_registrations, :lti_registration, index: { where: "lti_registration_id IS NOT NULL", algorithm: :concurrently, if_not_exists: true }, foreign_key: { to_table: :lti_registrations }, null: true, if_not_exists: true
    add_reference :developer_keys, :lti_registration, index: { where: "lti_registration_id IS NOT NULL", algorithm: :concurrently, if_not_exists: true }, foreign_key: { to_table: :lti_registrations }, null: true, if_not_exists: true
  end
end
