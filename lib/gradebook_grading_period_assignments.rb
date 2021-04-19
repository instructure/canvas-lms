# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

class GradebookGradingPeriodAssignments
  def initialize(course, student: nil, course_settings: nil)
    raise "Context must be a course" unless course.is_a?(Course)
    raise "Context must have an id" unless course.id

    @course = course
    @student = student
    @settings_for_course = course_settings || {
      'show_concluded_enrollments' => 'false',
      'show_inactive_enrollments' => 'false'
    }
  end

  def to_h
    return {} unless @course.grading_periods?

    the_query.each_with_object({}) do |(period_id, list), hash|
      hash[period_id || :none] = list.map(&:to_s)
    end
  end

  private

  def excluded_workflow_states
    excluded_workflow_states = ['deleted']
    excluded_workflow_states << 'completed' if @settings_for_course['show_concluded_enrollments'] != 'true'
    excluded_workflow_states << 'inactive' if @settings_for_course['show_inactive_enrollments'] != 'true'
    excluded_workflow_states
  end

  # One Query to rule them all, One Query to find them, One Query to bring them all, and in the darkness bind them to a hash
  def the_query
    GuardRail.activate(:secondary) do
      scope = Submission.
        active.
        joins(:assignment).
        joins("INNER JOIN #{Enrollment.quoted_table_name} enrollments ON enrollments.user_id = submissions.user_id").
        merge(Assignment.for_course(@course).active).
        where(enrollments: { course_id: @course, type: ['StudentEnrollment', 'StudentViewEnrollment'] }).
        where.not(enrollments: { workflow_state: excluded_workflow_states })

      scope = scope.where(user: @student) if @student
      scope.
        group(:grading_period_id).
        pluck(:grading_period_id, Arel.sql("array_agg(DISTINCT assignment_id)")).
        to_h
    end
  end
end
