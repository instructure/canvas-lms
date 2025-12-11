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

  SCAN_TAG = "resource_accessibility_scan"
  MAX_HTML_SIZE = 125.kilobytes
  MAX_PDF_SIZE = 5.megabytes

  def initialize(resource:)
    super()
    @resource = resource
  end

  def call
    return if scan_already_queued_or_in_progress?

    scan = first_or_initialize_scan
    delay(
      n_strand: [SCAN_TAG, @resource.course.account.global_id],
      singleton: "#{SCAN_TAG}_#{@resource.global_id}",
      priority: Delayed::LOW_PRIORITY
    ).scan_resource(scan:)
  end

  def call_sync
    scan = first_or_initialize_scan
    scan_resource(scan:)
    scan
  end

  def first_or_initialize_scan
    scan = AccessibilityResourceScan.where(context: @resource).first_or_initialize
    scan.assign_attributes(
      course_id: @resource.course.id,
      workflow_state: "queued",
      resource_name: @resource.try(:title),
      resource_workflow_state:,
      resource_updated_at: @resource.updated_at,
      issue_count: 0,
      error_message: nil
    )
    scan.save!
    scan
  end

  def scan_resource(scan:)
    scan.in_progress!
    @resource = scan.context

    return handle_size_limit_failure(scan) if over_size_limit?

    issues = scan_resource_for_issues

    scan.accessibility_issues.active.delete_all
    scan.accessibility_issues.create!(issues) if issues.any?

    scan.update(
      workflow_state: "completed",
      issue_count: issues.count
    )
    log_to_datadog(scan)
  rescue => e
    error_report = ErrorReport.log_exception(
      SCAN_TAG,
      e,
      {
        progress_id: scan.id,
        course_id: scan.course.id,
        course_name: scan.course.name
      }
    )
    handle_scan_failure(scan, error_report)
    Sentry.with_scope do |scope|
      scope.set_context(
        SCAN_TAG,
        {
          progress_id: scan.id,
          course_id: scan.course.id,
          course_name: scan.course.name,
          workflow_state: scan.workflow_state
        }
      )

      Sentry.capture_exception(e, level: :error)
    end
  end

  private

  def log_to_datadog(scan)
    tags = Utils::InstStatsdUtils::Tags.tags_for(scan.course.shard)
    InstStatsd::Statsd.distributed_increment("accessibility.resources_scanned", tags:)

    if scan.wiki_page_id?
      InstStatsd::Statsd.distributed_increment("accessibility.pages_scanned", tags:)
    elsif scan.assignment_id?
      InstStatsd::Statsd.distributed_increment("accessibility.assignments_scanned", tags:)
    end

    if scan.failed?
      Rails.logger.error("Scan failed with ID #{scan.global_id} for course #{scan.course.global_id}")
      InstStatsd::Statsd.distributed_increment("accessibility.resource_scan_failed", tags:)
    end
  end

  def scan_already_queued_or_in_progress?
    AccessibilityResourceScan.where(context: @resource)
                             .where(workflow_state: %w[queued in_progress])
                             .exists?
  end

  def over_size_limit?
    case @resource
    when WikiPage
      (@resource.body&.size || 0) > MAX_HTML_SIZE
    when Assignment
      (@resource.description&.size || 0) > MAX_HTML_SIZE
    when Attachment
      @resource.size > MAX_PDF_SIZE
    else
      false
    end
  end

  def handle_size_limit_failure(scan)
    error_message = case @resource
                    when Attachment
                      I18n.t(
                        "This file is too large to check. PDF attachments must not be greater than %{size} MB.",
                        { size: MAX_PDF_SIZE / 1.megabyte }
                      )
                    else
                      I18n.t(
                        "This content is too large to check. HTML body must not be greater than %{size} KB.",
                        { size: MAX_HTML_SIZE / 1.kilobyte }
                      )
                    end
    scan.update(
      workflow_state: "failed",
      error_message:
    )
    log_to_datadog(scan)
    Rails.logger.warn("[A11Y Scan] Skipped resource #{@resource&.id} due to size limit.")
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
                   check_content_accessibility(@resource.body.to_s)
                 when Assignment
                   check_content_accessibility(@resource.description.to_s)
                 when Attachment
                   check_pdf_accessibility(@resource)
                 else
                   raise ArgumentError, "Unsupported resource type: #{@resource.class.name}"
                 end
    raw_issues[:issues].map { |issue| build_issue_attributes(issue) }
  end

  def build_issue_attributes(issue)
    {
      course_id: @resource.course.id,
      context: @resource,
      rule_type: issue[:rule_id],
      node_path: issue[:path],
      metadata: {
        element: issue[:element],
        form: issue[:form],
      }
    }
  end

  def handle_scan_failure(scan, error_report)
    scan&.update(workflow_state: "failed", error_message: error_report.id)
    log_to_datadog(scan)
  end
end
