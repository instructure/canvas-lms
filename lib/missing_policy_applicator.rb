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

class MissingPolicyApplicator
  def self.apply_missing_deductions
    MissingPolicyApplicator.new.apply_missing_deductions
  end

  def apply_missing_deductions
    GuardRail.activate(:secondary) do
      recently_missing_submissions.find_in_batches do |submissions|
        filtered_submissions = submissions.reject { |s| s.grading_period&.closed? }
        filtered_submissions.group_by(&:assignment).each { |k, v| apply_missing_deduction(k, v) }
      end
    end
  end

  private

  def recently_missing_submissions
    now = Time.zone.now
    Submission.active
              .joins(assignment: { course: [:late_policy, :enrollments] })
              .where("enrollments.user_id = submissions.user_id")
              .preload(:grading_period, assignment: :post_policy, course: [:late_policy, :default_post_policy])
              .merge(Assignment.published)
              .merge(Enrollment.all_active_or_pending)
              .missing
              .where(score: nil,
                     grade: nil,
                     cached_due_date: 1.day.ago(now)..now,
                     late_policies: { missing_submission_deduction_enabled: true })
  end

  # Given submissions must all be for the same assignment
  def apply_missing_deduction(assignment, submissions)
    score = assignment.course.late_policy.points_for_missing(assignment.points_possible, assignment.grading_type)
    grade = assignment.score_to_grade(score)
    now = Time.zone.now

    GuardRail.activate(:primary) do
      plucked_submissions = submissions.pluck(:user_id, :id, :course_id)
      submissions = Submission.active.missing.where(id: submissions)

      submissions.update_all(
        score:,
        grade:,
        graded_at: now,
        grader_id: nil,
        posted_at: assignment.post_manually? ? nil : now,
        published_score: score,
        published_grade: grade,
        grade_matches_current_submission: true,
        updated_at: now,
        workflow_state: "graded"
      )

      if assignment.course.root_account.feature_enabled?(:missing_policy_applicator_emits_live_events)
        Canvas::LiveEvents.delay_if_production.submissions_bulk_updated(submissions)
      end

      if Account.site_admin.feature_enabled?(:fix_missing_policy_applicator_gradebook_history)
        Auditors::GradeChange.delay_if_production.bulk_record_submission_events(submissions.reload)
      end
      unique_users = submissions.map(&:user_id).uniq
      Auditors::GradeChange.delay_if_production(strand: "CreateParticipationsForMissingPolicy:#{assignment.root_account.global_id}").create_content_participations(plucked_submissions, assignment, unique_users)
      assignment.course.recompute_student_scores(unique_users)
    end
  end
end
