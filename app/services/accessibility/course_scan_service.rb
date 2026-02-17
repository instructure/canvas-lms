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

class Accessibility::CourseScanService < ApplicationService
  include Accessibility::Concerns::CourseStatisticsQueueable

  SCAN_TAG = "course_accessibility_scan"

  class ScanLimitExceededError < StandardError; end

  def self.last_accessibility_course_scan(course)
    Progress.where(tag: SCAN_TAG, context: course).last
  end

  def self.queue_course_scan(course)
    progress = Progress.where(tag: SCAN_TAG, context_type: "Course", context_id: course.id).last
    return progress if progress&.pending?

    if course.exceeds_accessibility_scan_limit?
      raise ScanLimitExceededError, "Course exceeds accessibility scan limit"
    end

    progress = Progress.create!(tag: SCAN_TAG, context: course)

    n_strand = [SCAN_TAG, course.global_id]
    singleton = "#{SCAN_TAG}_#{course.global_id}"
    progress.process_job(self, :scan, { n_strand:, singleton: })
    progress
  end

  def self.scan(progress)
    service = new(course: progress.context)
    service.scan_course
    progress.set_results({})
    progress.complete!
    service.queue_course_statistics(progress.context)
  rescue => e
    progress.fail!
    ErrorReport.log_exception(
      SCAN_TAG,
      e,
      {
        progress_id: progress.id,
        course_id: progress.context.id,
        course_name: progress.context.name
      }
    )
    Sentry.with_scope do |scope|
      scope.set_context(
        SCAN_TAG,
        {
          progress_id: progress.global_id,
          course_id: progress.context.global_id,
          course_name: progress.context.name,
          workflow_state: progress.workflow_state
        }
      )

      Sentry.capture_exception(e, level: :error)
    end
    raise
  end

  def initialize(course:)
    super()
    @course = course
    @root_account = course.root_account
  end

  def scan_course
    scan_resources(@course.wiki_pages.not_deleted, :wiki_page_id)
    scan_resources(@course.assignments.active.not_excluded_from_accessibility_scan.except(:order), :assignment_id)

    if @course.a11y_checker_additional_resources?
      scan_resources(@course.discussion_topics.scannable.except(:order), :discussion_topic_id)
      scan_resources(@course.announcements.active.except(:order), :announcement_id)
      scan_syllabus
    end
  end

  private

  def scan_resources(resources, resource_id_column)
    batch_size = Setting.get("accessibility_scan_batch_size", "200").to_i

    resources.in_batches(of: batch_size) do |resource_batch|
      loaded_resource_batch = resource_batch.to_a
      resource_batch_ids = loaded_resource_batch.map(&:id)

      scans_by_resource_id = AccessibilityResourceScan
                             .where(root_account: @root_account)
                             .where(resource_id_column => resource_batch_ids)
                             .index_by(&resource_id_column)

      loaded_resource_batch.each do |resource|
        scan = scans_by_resource_id[resource.id]

        next unless needs_scan?(resource, scan)

        resource_scanner_service = Accessibility::ResourceScannerService.new(resource:)
        if scan
          resource_scanner_service.scan_resource(scan:)
        else
          resource_scanner_service.call_sync
        end
      end
    end
  end

  def scan_syllabus
    # Skip if syllabus is empty
    return if @course.syllabus_body.blank?

    scan = AccessibilityResourceScan.find_by(course_id: @course.id, is_syllabus: true)

    return unless needs_scan?(@course, scan)

    resource = Accessibility::SyllabusResource.new(@course)

    resource_scanner_service = Accessibility::ResourceScannerService.new(resource:)
    if scan
      resource_scanner_service.scan_resource(scan:)
    else
      resource_scanner_service.call_sync
    end
  end

  def needs_scan?(resource, scan)
    return true if scan.nil?

    return false if scan.workflow_state.in?(%w[queued in_progress])

    return true unless Account.site_admin.feature_enabled?(:a11y_checker_course_scan_conditional_resource_scan)

    # scan.resource_updated_at is not used here purposefully to avoid issues with clock skew
    # when after_commit triggers scans on updates. Instead, we rely on the scan's updated_at timestamp.
    resource.updated_at > scan.updated_at
  end
end
