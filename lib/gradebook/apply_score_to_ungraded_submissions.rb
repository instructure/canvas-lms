# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

module Gradebook
  class ApplyScoreToUngradedSubmissions
    MAX_ERROR_COUNT = 100

    Options = Struct.new(
      :excused,
      :mark_as_missing,
      :only_apply_to_past_due,
      :percent,
      :assignment_ids,
      :student_ids,
      keyword_init: true
    )

    def self.queue_apply_score(course:, grader:, options:)
      progress = Progress.create!(context: course, tag: "apply_score_to_ungraded_assignments")
      progress.process_job(self, :process_apply_score, {}, course, grader, options)
      progress
    end

    def self.process_apply_score(progress, course, grader, options)
      Delayed::Batch.serial_batch(
        priority: Delayed::LOW_PRIORITY,
        n_strand: ["apply_score_to_ungraded_assignments", course.root_account.global_id]
      ) do
        errors = []
        affected_user_ids = Set.new

        matching_submissions_scope(course, grader, options).find_each do |submission|
          # A batch update is a possibility here, but we follow the lead of
          # similar processes like the submissions bulk update in issuing
          # individual updates to each submission so that the appropriate
          # callbacks happen.
          process_submission(submission, grader, options)
          affected_user_ids.add(submission.user_id)
        rescue
          if errors.count < MAX_ERROR_COUNT
            errors << {
              assignment_id: submission.assignment_id,
              error: :failed_to_update,
              student_id: submission.user_id
            }
          end
        end

        progress&.complete!
      ensure
        course.recompute_student_scores(affected_user_ids) if affected_user_ids.any?
        progress&.set_results({ errors: })
      end
    end

    def self.matching_submissions_scope(course, grader, options)
      students = course.students_visible_to(grader).where(id: options.student_ids)
      assignments = course.assignments.where(id: options.assignment_ids).where.not(submission_types: "not_graded")
      submissions = Submission.active
                              .joins(:assignment)
                              .preload(:assignment, :user)
                              .where(assignment: assignments)
                              .where.not("assignments.moderated_grading IS TRUE AND assignments.grades_published_at IS NULL")
                              .where.not(["assignments.moderated_grading IS TRUE AND assignments.final_grader_id != ?", grader.id])
                              .where(user: students)
                              .ungraded
                              .where("submissions.excused IS NOT TRUE")
      submissions = submissions.where("cached_due_date < ?", Time.zone.now) if options.only_apply_to_past_due
      submissions
    end
    private_class_method :matching_submissions_scope

    def self.process_submission(submission, grader, options)
      assignment = submission.assignment

      # call assignment.points_possible.to_f because points_possible could be nil
      percent_score = options.percent.to_f * assignment.points_possible.to_f / 100 if options.percent.present?

      Submission.suspend_callbacks(:apply_late_policy) do
        assignment.grade_student(
          submission.user,
          grader:,
          excused: options.excused,
          score: percent_score,
          skip_grade_calc: true
        )
      end

      # If mark_as_missing is true, we need to surreptitiously update the late policy
      # status, since calling grade_student will clear it. There may be a less clunky
      # way to do this.
      submission.update_column(:late_policy_status, "missing") if options.mark_as_missing
    end
    private_class_method :process_submission
  end
end
