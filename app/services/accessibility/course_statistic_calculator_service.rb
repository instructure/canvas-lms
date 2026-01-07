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

class Accessibility::CourseStatisticCalculatorService
  SCAN_TAG = "accessibility_course_statistics"
  ERROR_TAG = "accessibility_course_statistics"

  def self.calculation_delay
    Setting.get("accessibility_course_statistics_calculation_delay", 5.minutes.to_s).to_i.seconds
  end

  def self.queue_calculation(course)
    statistic = AccessibilityCourseStatistic.find_or_create_by!(course:)

    return statistic if statistic.calculation_pending?

    statistic.update!(workflow_state: "queued")

    delay(
      n_strand: [SCAN_TAG, course.account.global_id],
      singleton: "#{SCAN_TAG}_#{course.global_id}",
      run_at: calculation_delay.from_now
    ).perform_calculation(statistic.id)

    statistic
  end

  def self.perform_calculation(statistic_id)
    statistic = AccessibilityCourseStatistic.find(statistic_id)
    new(statistic:).calculate
  end

  def initialize(statistic:)
    @statistic = statistic
  end

  def calculate
    @statistic.update!(workflow_state: "in_progress")

    # TODO: Implement actual calculation logic here

    @statistic.update!(workflow_state: "active")
  rescue => e
    @statistic.update!(workflow_state: "failed")
    ErrorReport.log_exception(
      ERROR_TAG,
      e,
      {
        statistic_id: @statistic.global_id,
        course_id: @statistic.course_id,
        course_name: @statistic.course.name
      }
    )
    Sentry.with_scope do |scope|
      scope.set_context(
        ERROR_TAG,
        {
          statistic_id: @statistic.global_id,
          course_id: @statistic.course.global_id,
          course_name: @statistic.course.name,
        }
      )
      Sentry.capture_exception(e, level: :error)
    end
    raise
  end
end
