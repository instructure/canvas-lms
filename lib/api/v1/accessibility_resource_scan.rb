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

module Api::V1::AccessibilityResourceScan
  include Api::V1::Json

  def accessibility_resource_scan_json(scan)
    resource = scan.context
    resource_id = resource&.id
    resource_type = resource&.class&.name
    scan_completed = scan.workflow_state == "completed"
    {
      id: scan.id,
      resource_id:,
      resource_type:,
      resource_name: scan.resource_name,
      resource_workflow_state: scan.resource_workflow_state,
      resource_updated_at: scan.resource_updated_at&.iso8601 || "",
      resource_url: scan.context_url,
      resource_scan_path: scan.resource_scan_path,
      workflow_state: scan.workflow_state,
      error_message: scan.error_message || "",
      issue_count: scan_completed ? scan.issue_count : 0,
      issues: scan_completed ? scan.accessibility_issues.select(&:active?).map { |issue| accessibility_issue_json(issue) } : []
    }
  end

  def accessibility_issue_json(issue)
    rule = Accessibility::Rule.registry[issue.rule_type]
    {
      id: issue.id,
      rule_id: issue.rule_type,
      element: issue.metadata["element"],
      display_name: rule&.display_name,
      message: rule&.message,
      why: rule&.why,
      path: issue.node_path,
      issue_url: rule&.class&.link,
      form: issue.metadata["form"]
    }
  end
end
