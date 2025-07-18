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

class Accessibility::ResourceScannerService < ApplicationService
  include Accessibility::Issue::ContentChecker

  def initialize(resource:)
    super()
    @resource = resource
  end

  def call
    return if scan_already_queued_or_in_progress?

    scan = AccessibilityResourceScan.for_context(@resource).first_or_initialize
    scan.assign_attributes(
      course: @resource.course,
      workflow_state: "queued",
      resource_name: @resource.try(:title),
      resource_workflow_state:,
      resource_updated_at: @resource.updated_at,
      issue_count: 0,
      error_message: nil
    )
    scan.save!

    delay(singleton: "accessibility_scan_resource_#{@resource.global_id}").scan_resource(scan:)
  end

  def scan_resource(scan:)
    scan.in_progress!
    @resource = scan.context

    issues = scan_resource_for_issues

    scan.accessibility_issues.delete_all
    scan.accessibility_issues.create!(issues) if issues.any?

    scan.update(
      workflow_state: "completed",
      issue_count: issues.count
    )
  rescue => e
    handle_scan_failure(scan, e)
  end

  private

  def scan_already_queued_or_in_progress?
    AccessibilityResourceScan.for_context(@resource)
                             .where(workflow_state: %w[queued in_progress])
                             .exists?
  end

  def resource_workflow_state
    case @resource
    when WikiPage
      @resource.active? ? "published" : "unpublished"
    when Assignment
      @resource.published? ? "published" : "unpublished"
    when Attachment
      @resource.processed? ? "published" : "unpublished"
    else
      raise ArgumentError, "Unsupported resource type: #{@resource.class.name}"
    end
  end

  def scan_resource_for_issues
    raw_issues = case @resource
                 when WikiPage
                   check_content_accessibility(@resource.body)
                 when Assignment
                   check_content_accessibility(@resource.description)
                 when Attachment
                   check_pdf_accessibility(@resource)
                 else
                   raise ArgumentError, "Unsupported resource type: #{@resource.class.name}"
                 end
    raw_issues[:issues].map { |issue| build_issue_attributes(issue) }
  end

  def build_issue_attributes(issue)
    {
      course: @resource.course,
      context: @resource,
      rule_type: issue[:rule_id],
      node_path: issue[:path],
      metadata: {
        element: issue[:element],
        form: issue[:form],
      }
    }
  end

  def handle_scan_failure(scan, error)
    Rails.logger.warn("[A11Y Scan] Failed to scan resource #{@resource&.id}: #{error.message}")
    scan&.update(workflow_state: "failed", error_message: error.message)
  end
end
