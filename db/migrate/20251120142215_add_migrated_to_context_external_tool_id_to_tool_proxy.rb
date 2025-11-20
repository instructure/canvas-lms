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

class AddMigratedToContextExternalToolIdToToolProxy < ActiveRecord::Migration[8.0]
  tag :predeploy
  disable_ddl_transaction!

  def up
    add_reference :lti_tool_proxies,
                  :migrated_to_context_external_tool,
                  if_not_exists: true,
                  foreign_key: { to_table: :context_external_tools, on_delete: :nullify },
                  index: {
                    algorithm: :concurrently,
                    if_not_exists: true,
                    where: "migrated_to_context_external_tool_id IS NOT NULL"
                  },
                  null: true
  end

  def down
    remove_reference :lti_tool_proxies,
                     :migrated_to_context_external_tool,
                     if_exists: true,
                     foreign_key: { to_table: :context_external_tools, on_delete: :nullify },
                     index: true
  end
end
