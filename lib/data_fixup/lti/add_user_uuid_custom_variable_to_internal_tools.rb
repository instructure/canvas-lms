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

# Update the tool's DeveloperKey -> Lti::ToolConfiguration only once, since that will
# kick off a separate job that updates all tools associated to this key.
#
# The custom variable is only added if it doesn't already exist.

module DataFixup::Lti::AddUserUuidCustomVariableToInternalTools
  def self.run
    [
      { target_link_id: "sistemic.", custom_field: "UserUUID" },
      { target_link_id: "sistemic-", custom_field: "UserUUID" },
      { target_link_id: ".eesysoft.com", custom_field: "canvas_user_uuid" }
    ].each { |tool| update_tool_config(tool[:target_link_id], tool[:custom_field]) }
  end

  def self.update_tool_config(target_link_id, custom_field)
    tool_configs = Lti::ToolConfiguration.joins(:developer_key).where(developer_keys: { workflow_state: "active" })
                                         .where("target_link_uri LIKE ?", "%#{target_link_id}%").distinct
    return if tool_configs.empty?

    tool_configs.each do |tc|
      next if tc.custom_fields[custom_field]

      tc.custom_fields ||= {}
      tc.custom_fields[custom_field] = "$vnd.instructure.User.uuid"
      tc.save!
    end
  end
end
