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

module Accessibility
  class ResourceScanController < ApplicationController
    include AccessibilityFilters

    before_action :require_context
    before_action :require_user
    before_action :check_authorized_action

    ALLOWED_SORTS = %w[resource_name resource_type resource_workflow_state resource_updated_at issue_count].freeze

    # GET /courses/:course_id/accessibility/resource_scan
    # Params:
    #   page, per_page           – pagination
    #   sort, direction          – sorting, see ALLOWED_SORTS
    def index
      scans = AccessibilityResourceScan
              .preload(:accessibility_issues)
              .where(course_id: @context.id)

      scans = apply_sorting(scans)
      scans = apply_accessibility_filters(scans, params[:filters], params[:search]) if params[:filters].present? || params[:search].present?

      base_url = resource_scan_course_accessibility_index_path(@context)
      paginated = Api.paginate(scans, self, base_url)

      render json: paginated.map { |scan| scan_attributes(scan) }
    end

    # GET /courses/:course_id/accessibility/resource_scan/poll
    # Params:
    #   scan_ids – comma-separated list of scan IDs to poll
    # Returns updated scan data for scans that are queued or in progress
    def poll
      scan_ids = params[:scan_ids]&.split(",")&.map(&:to_i) || []

      return render json: { scans: [] } if scan_ids.empty?

      max_poll_ids = Setting.get("accessibility_resource_scan_poll_max_ids", "10").to_i
      if scan_ids.length > max_poll_ids
        return render json: { error: "Too many scan IDs. Maximum allowed: #{max_poll_ids}" }, status: :bad_request
      end

      scans = AccessibilityResourceScan
              .where(id: scan_ids, course_id: @context.id)
              .preload(:accessibility_issues)

      render json: { scans: scans.map { |scan| scan_attributes(scan) } }
    end

    private

    def check_authorized_action
      return render status: :forbidden unless @context.try(:a11y_checker_enabled?)

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
    # @param scan [AccessibilityResourceScan] the scan record
    # @return [Hash] the scan attributes
    def scan_attributes(scan)
      resource = scan.context
      resource_id = resource&.id
      resource_type = resource&.class&.name
      scan_completed = scan.workflow_state == "completed"

      result = {
        id: scan.id,
        resource_id:,
        resource_type:,
        resource_name: scan.resource_name,
        resource_workflow_state: scan.resource_workflow_state,
        resource_updated_at: scan.resource_updated_at&.iso8601 || "",
        resource_url: scan.context_url,
        workflow_state: scan.workflow_state,
        error_message: scan.error_message || ""
      }

      # Only include issue-related data when the scan is completed
      if scan_completed
        result[:issue_count] = scan.issue_count
        result[:issues] = scan.accessibility_issues.select(&:active?).map { |issue| issue_attributes(issue) }
      end

      result
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
        issue_url: rule&.class&.link,
        form: issue.metadata["form"]
      }
    end
  end
end
