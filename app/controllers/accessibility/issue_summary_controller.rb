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
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

module Accessibility
  class IssueSummaryController < ApplicationController
    include AccessibilityFilters

    before_action :require_context
    before_action :require_user
    before_action :check_authorized_action

    def show
      summary_data = calculate_issue_summary
      render json: summary_data, status: :ok
    end

    private

    def check_authorized_action
      return render status: :forbidden unless @context.try(:a11y_checker_enabled?)

      authorized_action(@context, @current_user, [:read, :update])
    end

    def calculate_issue_summary
      scans = AccessibilityResourceScan
              .preload(:accessibility_issues)
              .where(course_id: @context.id)

      scans = apply_accessibility_filters(scans, params[:filters], params[:search]) if params[:filters].present? || params[:search].present?

      all_issues = AccessibilityIssue
                   .active
                   .joins(:accessibility_resource_scan)
                   .where(accessibility_resource_scans: { id: scans.select(:id) })

      total_count = all_issues.count
      issue_count_by_rule_type = all_issues.group(:rule_type).count

      {
        total: total_count,
        by_rule_type: issue_count_by_rule_type
      }
    end
  end
end
