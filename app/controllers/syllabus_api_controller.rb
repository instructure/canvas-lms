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

class SyllabusApiController < ApplicationController
  include Api::V1::AccessibilityResourceScan

  before_action :require_context
  before_action :require_course_context, only: [:accessibility_scan, :accessibility_queue_scan]

  # @API Scan syllabus for accessibility issues
  #
  # Scans a course syllabus for accessibility issues and returns the results.
  #
  # @returns AccessibilityResourceScan
  def accessibility_scan
    return render_unauthorized_action unless @context.grants_any_right?(
      @current_user,
      *RoleOverride::GRANULAR_MANAGE_COURSE_CONTENT_PERMISSIONS
    )
    return render_unauthorized_action unless @context.a11y_checker_enabled?

    # Wrap the course in SyllabusResource to make it scannable
    syllabus_resource = Accessibility::SyllabusResource.new(@context)
    scan = Accessibility::ResourceScannerService.new(resource: syllabus_resource).call_sync
    render json: accessibility_resource_scan_json(scan)
  end

  # @API Queue syllabus accessibility scan
  #
  # Queues a course syllabus for accessibility scanning.
  #
  # @returns AccessibilityResourceScan
  def accessibility_queue_scan
    return render_unauthorized_action unless @context.grants_any_right?(
      @current_user,
      *RoleOverride::GRANULAR_MANAGE_COURSE_CONTENT_PERMISSIONS
    )
    return render_unauthorized_action unless @context.a11y_checker_enabled?

    # Wrap the course in SyllabusResource to make it scannable
    syllabus_resource = Accessibility::SyllabusResource.new(@context)
    scan = Accessibility::ResourceScannerService.new(resource: syllabus_resource).call
    render json: accessibility_resource_scan_json(scan)
  end

  private

  def require_course_context
    unless @context.is_a?(Course)
      render json: { error: "Invalid context" }, status: :bad_request
    end
  end
end
