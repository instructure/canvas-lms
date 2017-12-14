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

class LatePolicyApplicator
  def self.for_course(course)
    return unless course.published?
    return unless course.assignments.published.exists?

    new(course).send_later_if_production_enqueue_args(
      :process,
      singleton: "late_policy_applicator:calculator:Course:#{course.global_id}"
    )
  end

  def self.for_assignment(assignment)
    return unless assignment.published? && assignment.points_possible&.positive?
    return unless assignment.course

    new(assignment.course, [assignment]).send_later_if_production_enqueue_args(
      :process,
      singleton: "late_policy_applicator:calculator:Assignment:#{assignment.global_id}"
    )
  end

  def initialize(course, assignments = [])
    @course = course
    @assignments = if assignments.present?
      assignments.select(&:published?)
    else
      @course.assignments.published
    end

    @relevant_submissions = {}
  end

  def process
    return unless needs_processing?

    late_policy = @course.late_policy
    user_ids = []

    @assignments.each do |assignment|
      relevant_submissions(assignment).find_each do |submission|
        user_ids << submission.user_id if process_submission(late_policy, assignment, submission)
      end
    end

    @course.recompute_student_scores(user_ids.uniq) if user_ids.present?
  end

  private

  def process_submission(late_policy, assignment, submission)
    submission.apply_late_policy(late_policy, assignment)
    if submission.changed?
      submission.skip_grade_calc = true
      return submission.save!
    end

    false
  end

  def relevant_submissions(assignment)
    @relevant_submissions[assignment.id] ||= begin
      if @course.late_policy.late_submission_deduction_enabled
        query = late_submissions_for(assignment).union(no_longer_late_submissions_for(assignment))
        if @course.late_policy.missing_submission_deduction_enabled
          query = query.union(missing_submissions_for(assignment))
        end
      else
        query = missing_submissions_for(assignment)
      end

      query.left_joins(:grading_period).merge(GradingPeriod.open)
    end
  end

  def submissions(assignment)
    enrollments = assignment.course.admin_visible_student_enrollments
    assignment.submissions.for_enrollments(enrollments)
  end

  def late_submissions_for(assignment)
    submissions(assignment).late.where.not(score: nil)
  end

  def no_longer_late_submissions_for(assignment)
    submissions(assignment).not_late.where("submissions.points_deducted > 0")
  end

  def missing_submissions_for(assignment)
    submissions(assignment).missing.where(score: nil, grade: nil)
  end

  def needs_processing?
    (@course.late_policy&.missing_submission_deduction_enabled ||
      @course.late_policy&.late_submission_deduction_enabled) && @assignments.present?
  end
end
