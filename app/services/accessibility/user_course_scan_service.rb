# frozen_string_literal: true

# Copyright (C) 2026 - present Instructure, Inc.
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

class Accessibility::UserCourseScanService < ApplicationService
  SCAN_TAG = "user_accessibility_course_scan"
  ERROR_TAG = "user_accessibility_course_scan_error"

  # Queues a background job that scans all a11y-enabled courses for the user.
  #
  # Returns nil if the required feature flags are not enabled.
  # Returns the existing pending Progress if a scan is already queued or running.
  # Otherwise creates a new Progress and enqueues the job.
  #
  # The singleton prevents the same user from having more than one
  # scan job active at a time. The n_strand limits concurrency across
  # all users in the same root account. on_conflict: :overwrite ensures
  # that if two callers race past the pending? check, the losing Progress
  # is automatically canceled rather than left orphaned in queued state.
  def self.queue_user_courses_scan(user, root_account)
    return unless root_account.feature_enabled?(:educator_dashboard) &&
                  root_account.a11y_checker_account_statistics?

    progress = Progress.where(tag: SCAN_TAG, context: user, user:).last
    return progress if progress&.pending?

    progress = Progress.create!(tag: SCAN_TAG, context: user, user:)

    n_strand = [SCAN_TAG, root_account.global_id]
    singleton = "#{SCAN_TAG}_#{user.global_id}"

    progress.process_job(self, :perform_scan, { n_strand:, singleton:, on_conflict: :overwrite }, user.id, root_account.id)
    progress
  end

  def self.perform_scan(progress, user_id, root_account_id)
    user = User.find(user_id)
    root_account = Account.find(root_account_id)
    new(user:, root_account:).scan_user_courses
    progress.set_results({})
    progress.complete!
  rescue => e
    progress.fail!
    ErrorReport.log_exception(
      ERROR_TAG,
      e,
      { progress_id: progress.id, user_id:, root_account_id: }
    )
    Sentry.with_scope do |scope|
      scope.set_context(
        ERROR_TAG,
        { progress_id: progress.global_id, user_id:, root_account_id: }
      )
      Sentry.capture_exception(e, level: :error)
    end
    raise
  end

  def initialize(user:, root_account:)
    super()
    @user = user
    @root_account = root_account
  end

  # Queues a CourseScanService scan for each a11y-enabled course the user
  # teaches or designs. Per-course failures are logged individually and do
  # not abort the remaining courses.
  # ScanLimitExceededError is operational noise and is only logged via
  # ErrorReport. Unexpected errors are also captured in Sentry at :warning.
  #
  # NOTE: Each course produces one Progress record and one Delayed::Job write.
  # For users with a large number of courses this results in many DB writes
  # in a single job run. This will be addressed during scaling. (ref EGG-2606)
  def scan_user_courses
    educator_courses_with_a11y_enabled.each do |course|
      Accessibility::CourseScanService.queue_course_scan(course)
    rescue Accessibility::CourseScanService::ScanLimitExceededError => e
      ErrorReport.log_exception(
        ERROR_TAG,
        e,
        { user_id: @user.id, course_id: course.id, course_name: course.name }
      )
    rescue => e
      ErrorReport.log_exception(
        ERROR_TAG,
        e,
        { user_id: @user.id, course_id: course.id, course_name: course.name }
      )
      Sentry.capture_exception(e, level: :warning)
    end
  end

  private

  def educator_courses_with_a11y_enabled
    # TODO: This lookup and course level feature flag check is also used in
    # accessibility_course_statistics_controller.rb. This should be
    # extracted to the user model or a shared concern when scaling.
    #
    # NOTE: This query runs on the user's home shard only. Users with
    # cross-shard enrollments will silently miss courses on other shards.
    # This will be corrected during scaling (ref )
    educator_course_ids = @user
                          .enrollments
                          .active
                          .where(type: %w[TeacherEnrollment DesignerEnrollment])
                          .joins(:course)
                          .where.not(courses: { workflow_state: %w[completed deleted] })
                          .select(:course_id)

    if @root_account.feature_enabled?(:a11y_checker_ga1)
      Course.where(id: educator_course_ids)
    else
      Course.where(id: educator_course_ids)
            .preload(:account)
            .select(&:a11y_checker_enabled?)
    end
  end
end
