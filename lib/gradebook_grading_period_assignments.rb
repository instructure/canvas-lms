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
  def initialize(course, settings)
    raise "Context must be a course" unless course.is_a?(Course)
    raise "Context must have an id" unless course.id

    @course = course
    @settings_for_course = settings.fetch(@course.id, {
      'show_concluded_enrollments' => 'false',
      'show_inactive_enrollments' => 'false'
    })
  end

  def to_h
    return {} unless @course.grading_periods?
    the_query.transform_values {|list| list.map(&:to_s)}
  end

  private

  def excluded_workflow_states
    excluded_workflow_states = ['deleted']
    excluded_workflow_states << 'completed' if @settings_for_course['show_concluded_enrollments'] != 'true'
    excluded_workflow_states << 'inactive' if @settings_for_course['show_inactive_enrollments'] != 'true'
    excluded_workflow_states
  end

  def the_query
    Submission.
      active.
      joins(:assignment, user: :enrollments).
      merge(Assignment.for_course(@course).active).
      where(enrollments: { course_id: @course, type: ['StudentEnrollment', 'StudentViewEnrollment'] }).
      where.not(grading_period_id: nil, enrollments: { workflow_state: excluded_workflow_states }).
      group(:grading_period_id).
      pluck(:grading_period_id, "array_agg(DISTINCT assignment_id)").
      to_h
  end
end
