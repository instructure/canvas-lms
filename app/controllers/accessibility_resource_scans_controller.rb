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

    params[:filters] || {}

    if params[:filters].present?
      scans = apply_filters(scans)
    end

    base_url = course_accessibility_resource_scans_path(@context)
    paginated = Api.paginate(scans, self, base_url)

    render json: paginated.map { |scan, filtered_issues| scan_attributes(scan, issues: filtered_issues) }
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

  # Apply filtering to the supplied ActiveRecord::Relation of AccessibilityResourceScan
  # based on a JSON-encoded `filters` param. Filters include rule types, resource types,
  # workflow states, issue workflow states, and a date range.
  #
  # Invalid or missing filters are ignored. All conditions are combined with AND logic.
  #
  # @param relation [ActiveRecord::Relation<AccessibilityResourceScan>] the base query
  # @return [ActiveRecord::Relation<AccessibilityResourceScan>] if rule_types is not present
  # @return [Array<[AccessibilityResourceScan, Array<AccessibilityIssue>]>] if rule_types is present
  def apply_filters(relation)
    raw_filters = begin
      params[:filters].presence
    rescue
      {}
    end

    return relation unless raw_filters.present?

    rule_types      = raw_filters[:ruleTypes]
    artifact_types  = raw_filters[:artifactTypes]
    workflow_states = raw_filters[:workflowStates]
    from_date = begin
      Time.zone.parse(raw_filters[:fromDate])
    rescue
      nil
    end
    to_date = begin
      Time.zone.parse(raw_filters[:toDate])
    rescue
      nil
    end

    if rule_types.present?
      scan_issue_map = relation.to_a.filter_map do |scan|
        matching_issues = scan.accessibility_issues.select do |issue|
          rule_types.include?(issue.rule_type)
        end

        next nil if matching_issues.empty?

        [scan, matching_issues]
      end

      scan_issue_map = scan_issue_map.select do |scan, _|
        artifact_match = if artifact_types.present?
                           (artifact_types.include?("wiki_page") && scan.wiki_page_id.present?) ||
                             (artifact_types.include?("assignment") && scan.assignment_id.present?) ||
                             (artifact_types.include?("attachment") && scan.attachment_id.present?)
                         else
                           true
                         end

        workflow_match = workflow_states.blank? || workflow_states.include?(scan.resource_workflow_state)
        updated_at = scan.resource_updated_at

        date_match =
          (!from_date || (updated_at && updated_at >= from_date)) &&
          (!to_date   || (updated_at && updated_at <= to_date))

        artifact_match && workflow_match && date_match
      end

      return scan_issue_map
    end

    # Apply filters via ActiveRecord when no rule_types filter is present
    filtered = relation
    if artifact_types.present?
      conditions = []
      conditions << "wiki_page_id IS NOT NULL" if artifact_types.include?("wiki_page")
      conditions << "assignment_id IS NOT NULL" if artifact_types.include?("assignment")
      conditions << "attachment_id IS NOT NULL" if artifact_types.include?("attachment")
      filtered = filtered.where(conditions.join(" OR ")) if conditions.any?
    end

    filtered = filtered.where(resource_workflow_state: workflow_states) if workflow_states.present?
    filtered = filtered.where(resource_updated_at: from_date..) if from_date.present?
    filtered = filtered.where(resource_updated_at: ..to_date) if to_date.present?

    filtered
  end

  # Returns a hash representation of the scan, for JSON rendering.
  # @param scan [AccessibilityResourceScan]
  # @return [Hash]
  # @param scan [AccessibilityResourceScan]
  # @param issues [Array<AccessibilityIssue>, nil] optional filtered issues
  # @return [Hash]
  def scan_attributes(scan, issues: nil)
    resource_id, resource_type = scan.context_id_and_type
    scan_completed = scan.workflow_state == "completed"
    issue_count = if scan_completed
                    issues.nil? ? scan.issue_count : issues.count
                  else
                    0
                  end

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
      issue_count:,
      issues: scan_completed ? (issues || scan.accessibility_issues).map { |issue| issue_attributes(issue) } : []
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
