# frozen_string_literal: true

#
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

module DataFixup
  class RecalculateAdminEnrollmentStatesForCourseDatesRegression < CanvasOperations::DataFixup
    BUGGY_WINDOW_START = Time.utc(2026, 3, 12, 20, 0, 0)
    BUGGY_WINDOW_END = Time.utc(2026, 4, 15, 6, 0, 0)
    AFFECTED_STATES = %w[completed inactive].freeze
    AFFECTED_ENROLLMENT_TYPES = %w[TeacherEnrollment TaEnrollment DesignerEnrollment].freeze

    self.mode = :batch
    self.progress_tracking = false

    scope do
      now = Time.zone.now

      Enrollment
        .joins(:enrollment_state, course: :enrollment_term)
        .where(type: AFFECTED_ENROLLMENT_TYPES, workflow_state: %w[active invited])
        .where(enrollment_states: {
                 state: AFFECTED_STATES,
                 state_is_current: true,
                 updated_at: BUGGY_WINDOW_START..BUGGY_WINDOW_END
               })
        .where(courses: {
                 workflow_state: "available",
                 restrict_enrollments_to_course_dates: true
               })
        .where("courses.conclude_at IS NULL OR courses.conclude_at > ?", now)
        .where("enrollment_terms.end_at IS NOT NULL AND enrollment_terms.end_at < ?", now)
    end

    def process_batch(batch)
      enrollment_ids = batch.pluck(:id)
      return if enrollment_ids.empty?

      EnrollmentState
        .where(enrollment_id: enrollment_ids)
        .update_all(["lock_version = COALESCE(lock_version, 0) + 1, state_is_current = ?", false])

      EnrollmentState.process_states_for_ids(enrollment_ids)
    end
  end
end
