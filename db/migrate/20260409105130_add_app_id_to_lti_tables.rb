# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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
class AddAppIdToLtiTables < ActiveRecord::Migration[8.0]
  tag :predeploy
  disable_ddl_transaction!

  def change
    add_reference :context_external_tools,
                  :app,
                  null: true,
                  foreign_key: { to_table: :lti_registrations },
                  index: { where: "app_id IS NOT NULL", algorithm: :concurrently, if_not_exists: true }

    add_reference :lti_context_controls,
                  :app,
                  null: true,
                  foreign_key: { to_table: :lti_registrations },
                  index: { where: "app_id IS NOT NULL", algorithm: :concurrently, if_not_exists: true }

    add_reference :lti_registration_history_entries,
                  :app,
                  null: true,
                  foreign_key: { to_table: :lti_registrations },
                  index: { where: "app_id IS NOT NULL", algorithm: :concurrently, if_not_exists: true }
  end
end
