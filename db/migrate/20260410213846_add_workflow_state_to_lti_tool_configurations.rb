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
#

class AddWorkflowStateToLtiToolConfigurations < ActiveRecord::Migration[8.0]
  tag :predeploy

  def change
    add_column :lti_tool_configurations, :workflow_state, :string, default: "active", null: false, limit: 32, if_not_exists: true
    add_check_constraint :lti_tool_configurations,
                         "workflow_state IN ('active', 'deleted')",
                         name: "chk_workflow_state_enum",
                         if_not_exists: true
  end
end
