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

class AddDomainIndicesToLtiTables < ActiveRecord::Migration[8.0]
  tag :predeploy
  disable_ddl_transaction!

  def change
    # Add expression index for case-insensitive domain lookups on lti_tool_configurations
    # Using LOWER() in the index allows efficient case-insensitive domain matching
    add_index :lti_tool_configurations,
              "LOWER(domain)",
              name: "index_lti_tool_configurations_on_lower_domain",
              algorithm: :concurrently,
              if_not_exists: true,
              where: "domain IS NOT NULL"

    # Add expression index for case-insensitive domain lookups on lti_ims_registrations
    # Extracts domain from JSONB and lowercases it for efficient matching
    add_index :lti_ims_registrations,
              "LOWER(lti_tool_configuration->>'domain')",
              name: "index_lti_ims_registrations_on_lower_domain",
              algorithm: :concurrently,
              if_not_exists: true,
              where: "lti_tool_configuration->>'domain' IS NOT NULL"
  end
end
