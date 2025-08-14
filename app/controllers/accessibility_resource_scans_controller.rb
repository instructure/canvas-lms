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

class AccessibilityResourceScansController < ApplicationController
  before_action :require_context
  before_action :require_user
  before_action :validate_allowed

  ALLOWED_SORTS = %w[resource_name resource_type resource_workflow_state resource_updated_at issue_count].freeze

  # GET /courses/:course_id/accessibility_resource_scans
  # Params:
  #   page, per_page           – pagination
  #   sort, direction          – sorting, see ALLOWED_SORTS
  def index
    scans = AccessibilityResourceScan
            .preload(:accessibility_issues)
            .where(course_id: @context.id)

    scans = apply_sorting(scans)

    base_url = course_accessibility_resource_scans_path(@context)
    paginated = Api.paginate(scans, self, base_url)

    render json: paginated.map { |scan| scan_attributes(scan) }
  end

  private

  def validate_allowed
    return render_unauthorized_action unless tab_enabled?(Course::TAB_ACCESSIBILITY)

    authorized_action(@context, @current_user, [:read, :update])
  end

  # Apply sorting to the supplied ActiveRecord::Relation of AccessibilityResourceScan
  # Only whitelisted columns / virtual attributes from ALLOWED_SORTS are allowed.
  # If an invalid sort or direction is provided it falls back to safe defaults.
  #
  # @param relation [ActiveRecord::Relation] the base query
  # @return [ActiveRecord::Relation] the query with an ORDER BY clause applied
  def apply_sorting(relation)
    sort      = params[:sort].to_s.presence || "resource_name"
    sort      = "resource_name" unless ALLOWED_SORTS.include?(sort)

    direction = (params[:direction].to_s.downcase == "desc") ? "DESC" : "ASC"

    order_clause = case sort
                   when "resource_type"
                     type_case = <<~SQL.squish
                       CASE
                         WHEN wiki_page_id IS NOT NULL THEN 'wiki_page'
                         WHEN assignment_id IS NOT NULL THEN 'assignment'
                         WHEN attachment_id IS NOT NULL THEN 'attachment'
                       END
                     SQL
                     Arel.sql("#{type_case} #{direction}")
                   else
                     { sort => direction.downcase.to_sym }
                   end

    relation.order(order_clause)
  end

  # Returns a hash representation of the scan, for JSON rendering.
  # @param scan [AccessibilityResourceScan]
  # @return [Hash]
  def scan_attributes(scan)
    resource_id, resource_type = scan.context_id_and_type
    scan_completed = scan.workflow_state == "completed"
    {
      id: scan.id,
      resource_id:,
      resource_type:,
      resource_name: scan.resource_name,
      resource_workflow_state: scan.resource_workflow_state,
      resource_updated_at: scan.resource_updated_at&.iso8601 || "",
      resource_url: scan.context_url,
      workflow_state: scan.workflow_state,
      error_message: scan.error_message || "",
      issue_count: scan_completed ? scan.issue_count : 0,
      issues: scan_completed ? scan.accessibility_issues.map { |issue| issue_attributes(issue) } : []
    }
  end

  # Returns a hash representation of the issue, for JSON rendering.
  # @param issue [AccessibilityIssue]
  # @return [Hash]
  def issue_attributes(issue)
    rule = Accessibility::Rule.registry[issue.rule_type]
    {
      id: issue.id,
      rule_id: issue.rule_type,
      element: issue.metadata["element"],
      display_name: rule&.display_name,
      message: rule&.message,
      why: rule&.why,
      path: issue.node_path,
      issue_url: rule&.link,
      form: issue.metadata["form"]
    }
  end
end
