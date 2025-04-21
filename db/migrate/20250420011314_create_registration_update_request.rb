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
class CreateRegistrationUpdateRequest < ActiveRecord::Migration[7.1]
  tag :predeploy

  def change
    create_table :lti_registration_update_requests do |t|
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false
      t.timestamps
      t.uuid :uuid, null: true
      t.references :lti_registration, null: false, foreign_key: false
      t.jsonb :lti_ims_registration
      t.jsonb :canvas_lti_configuration
      t.references :created_by, null: true, foreign_key: { to_table: :users }
      t.references :updated_by, null: true, foreign_key: { to_table: :users }
      t.date :accepted_at, null: true
      t.date :rejected_at, null: true
      t.boolean :reinstall, null: false, default: false
      t.boolean :tool_initiated, null: false, default: false
      t.string :comment, limit: 500
      t.replica_identity_index
    end

    add_check_constraint :lti_registration_update_requests,
                         "(lti_ims_registration IS NOT NULL AND canvas_lti_configuration IS NULL) OR " \
                         "(lti_ims_registration IS NULL AND canvas_lti_configuration IS NOT NULL)",
                         name: "registration_config_mutually_exclusive"
  end
end
