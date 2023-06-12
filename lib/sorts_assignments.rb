# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

class SortsAssignments
  class InvalidBucketError < StandardError; end

  VALID_BUCKETS = %i[past overdue undated ungraded unsubmitted upcoming future].freeze

  def initialize(assignments_scope:, user:, session:, course:, requested_user: nil)
    @assignments_scope = assignments_scope
    @user = user
    @session = session
    @course = course
    @requested_user = requested_user
  end

  def assignments(bucket, &)
    raise InvalidBucketError if VALID_BUCKETS.exclude?(bucket)

    @now = Time.zone.now
    filter(bucket, &)
  end

  private

  def filter(bucket)
    assignments_in_bucket = buckets.fetch(bucket).call(assignments_for_students)
    if block_given?
      yield assignments_in_bucket
    else
      @assignments_scope.where(id: assignments_in_bucket)
    end
  end

  def buckets
    {
      past: filters[:has_date] >> filters[:past_due],
      overdue: (
        filters[:has_date] >> filters[:past_due] >>
          filters[:expects_submission].call(additional_excludes: %w[external_tool online_quiz attendance]) >>
          filters[:not_submitted_or_graded] >> filters[:can_submit]
      ),
      undated: filters[:has_no_date],
      ungraded: filters[:expects_submission].call >> filters[:needs_grading],
      unsubmitted: filters[:expects_submission].call >> filters[:not_submitted_or_graded],
      upcoming: filters[:has_date] >> filters[:due_soon],
      future: filters[:due_in_future]
    }
  end

  def filters
    @filters ||= {
      has_no_date: ->(scope) { scope.where(submissions: { cached_due_date: nil }) },
      has_date: ->(scope) { scope.where.not(submissions: { cached_due_date: nil }) },
      past_due: ->(scope) { scope.where("submissions.cached_due_date < ?", @now) },
      due_in_future: ->(scope) { scope.where("submissions.cached_due_date IS NULL OR submissions.cached_due_date >= ?", @now) },
      due_soon: ->(scope) { scope.where("submissions.cached_due_date >= ? AND submissions.cached_due_date <= ?", @now, 1.week.from_now(@now)) },
      expects_submission: lambda do |additional_excludes: ["external_tool"]|
        ->(scope) { scope.expecting_submission(additional_excludes:) }
      end,
      needs_grading: ->(scope) { scope.where(Submission.needs_grading_conditions) },
      not_submitted_or_graded: ->(scope) { scope.merge(Submission.not_submitted_or_graded) },
      can_submit: lambda do |scope|
        students_by_id = students.index_by(&:id)
        students_by_assignment_id = scope.pluck("submissions.assignment_id", "submissions.user_id").each_with_object({}) do |(assignment_id, user_id), acc|
          acc[assignment_id] ||= []
          acc[assignment_id] << students_by_id[user_id]
        end

        assignments = @course.assignments.except(:order).where(id: students_by_assignment_id.keys).select do |assignment|
          submittable_by_any_student?(assignment, students_by_assignment_id[assignment.id])
        end

        @course.assignments.where(id: assignments).except(:order)
      end
    }
  end

  def submittable_by_any_student?(assignment, students)
    students.any? { |student| student.present? && assignment.grants_right?(student, :submit) }
  end

  def assignments_for_students
    @course.assignments.where(id: assignment_ids).except(:order).joins(:submissions).where(submissions: { user: students })
  end

  def assignment_ids
    @assignment_ids ||= @assignments_scope.pluck(:id)
  end

  def students
    @students ||= if @requested_user.present? && @user != @requested_user
                    [@requested_user]
                  elsif @course.grants_right?(@user, @session, :read_as_admin)
                    @course.students_visible_to(@user).merge(Enrollment.of_student_type).distinct.to_a
                  elsif @course.observers.where(id: @user).exists?
                    ObserverEnrollment.observed_students(@course, @user).keys
                  else
                    [@user]
                  end
  end
end
