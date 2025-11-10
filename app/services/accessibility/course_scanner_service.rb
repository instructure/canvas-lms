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

class Accessibility::CourseScannerService < ApplicationService
  SCAN_TAG = "course_accessibility_scan"

  class ScanLimitExceededError < StandardError; end

  def self.last_accessibility_scan_progress_by_course(course)
    Progress.where(tag: SCAN_TAG, context: course).last
  end

  def self.queue_scan_course(course)
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
    @course.wiki_pages.not_deleted.find_each do |resource|
      Accessibility::ResourceScannerService.call(resource:)
    end
    @course.assignments.active.except(:order).find_each do |resource|
      Accessibility::ResourceScannerService.call(resource:)
    end
  end
end
