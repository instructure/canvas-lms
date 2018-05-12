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

class MissingPolicyApplicator
  def self.apply_missing_deductions
    MissingPolicyApplicator.new.apply_missing_deductions
  end

  def apply_missing_deductions
    recently_missing_submissions.find_in_batches do |submissions|
      filtered_submissions = submissions.reject { |s| s.grading_period&.closed? }
      filtered_submissions.group_by(&:assignment).each(&method(:apply_missing_deduction))
    end
  end

  private

  def recently_missing_submissions
    now = Time.zone.now
    Submission.active.
      joins(assignment: {course: :late_policy}).
      eager_load(:grading_period, assignment: { course: :late_policy }).
      for_enrollments(Enrollment.all_active_or_pending).
      missing.
      merge(Assignment.submittable).
      where(score: nil, grade: nil, cached_due_date: 1.day.ago(now)..now,
             late_policies: { missing_submission_deduction_enabled: true })
  end

  # Given submissions must all be for the same assignment
  def apply_missing_deduction(assignment, submissions)
    score = assignment.course.late_policy.points_for_missing(assignment.points_possible, assignment.grading_type)
    grade = assignment.score_to_grade(score)

    # We are using update_all here for performance reasons
    # rubocop:disable SkipsModelValidations
    Submission.active.where(id: submissions).update_all(
      score: score,
      grade: grade,
      published_score: score,
      published_grade: grade,
      workflow_state: "graded"
    )
    # rubocop:enable SkipsModelValidations

    assignment.course.recompute_student_scores(submissions.map(&:user_id).uniq)
  end
end
