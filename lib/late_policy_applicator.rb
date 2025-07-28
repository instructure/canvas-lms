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

class LatePolicyApplicator
  def self.for_course(course, assignment_ids = [])
    return unless course.published?
    return unless course.assignments.published.exists?

    # If assignment_ids is empty, we will process all assignments in the course.
    # If assignment_ids is present, we will only process those specific assignments.
    # This allows for flexibility in processing specific assignments if needed.
    assignments = if assignment_ids.present?
                    AbstractAssignment.where(context: course, id: assignment_ids).published.has_no_sub_assignments
                  else
                    []
                  end

    assignment_hash = assignment_ids.present? ? Digest::SHA256.hexdigest(assignment_ids.map(&:to_i).sort.join(",")) : "N/A"

    new(course, assignments).delay_if_production(
      singleton: "late_policy_applicator:calculator:Course:#{course.global_id}:AssignmentsHash:#{assignment_hash}",
      n_strand: ["LatePolicyApplicator", course.root_account.global_id]
    ).process
  end

  def self.for_assignment(assignment)
    return if assignment.has_sub_assignments?
    return unless assignment.published? && assignment.points_possible&.positive?
    return unless assignment.course

    new(assignment.course, [assignment]).delay_if_production(
      singleton: "late_policy_applicator:calculator:Assignment:#{assignment.global_id}",
      n_strand: ["LatePolicyApplicator", assignment.root_account.global_id]
    ).process
  end

  def initialize(course, assignments = [])
    @course = course
    @assignments = if assignments.present?
                     assignments.select { |a| a.published? && !a.has_sub_assignments? }
                   else
                     AbstractAssignment.where(context_id: course.id, context_type: "Course").published.has_no_sub_assignments
                   end

    @relevant_submissions = {}
  end

  def process
    return unless needs_processing?

    late_policy = @course.late_policy
    user_ids = []
    @assignments.each do |assignment|
      relevant_submissions(assignment).find_each do |submission|
        submission.assignment = assignment
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

      query.eager_load(:grading_period).merge(GradingPeriod.open).preload(:stream_item, :user)
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
