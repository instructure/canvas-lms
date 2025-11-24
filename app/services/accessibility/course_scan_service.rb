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

    # By default this will be 1 concurrent run / course, which is fine
    n_strand = [SCAN_TAG, course.global_id]
    progress.process_job(self, :scan, { n_strand: })
    progress
  end

  def self.scan(progress)
    service = new(course: progress.context)
    service.scan_course
    progress.set_results({})
    progress.complete!
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
  end

  def scan_course
    scan_resources(@course.wiki_pages.not_deleted, :wiki_page_id)
    scan_resources(@course.assignments.active.except(:order), :assignment_id)
  end

  private

  def scan_resources(resources, column_name)
    resource_ids = resources.pluck(:id)

    scans_by_resource_id = AccessibilityResourceScan
                           .where(column_name => resource_ids)
                           .index_by(&column_name)

    resources.find_each do |resource|
      last_scan = scans_by_resource_id[resource.id]
      next unless needs_scan?(resource, last_scan)

      Accessibility::ResourceScannerService.call(resource:)
    end
  end

  def needs_scan?(resource, last_scan)
    return true if last_scan.nil?

    # last_scan.resource_updated_at is not used here purposefully to avoid issues with clock skew
    # when after_commit triggers scans on updates. Instead, we rely on the scan's updated_at timestamp.
    resource.updated_at > last_scan.updated_at
  end
end
