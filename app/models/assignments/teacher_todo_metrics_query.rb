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

module Assignments
  # Teacher-facing submission metrics for a single assignment, used by the
  # Educator Dashboard's Smart Todo widget (behind the `educator_dashboard`
  # feature flag).
  #
  # SCALING NOTES — read before promoting beyond EAP:
  #   This implementation prioritizes readability over performance. It runs
  #   five separate count queries per assignment and has no caching, so a
  #   teacher's todo list with N assignments costs 5N round-trips on every
  #   render. Fine for experimentation and EAP cohorts; not fine at GA scale
  #   (~6M DAU).
  #
  #   Hardening tracked in EGG-2454:
  #     - Collapse the five counts into a single `pick` using
  #       `COUNT(...) FILTER (WHERE ...)` so one scan of
  #       `index_submissions_needs_grading` covers all buckets.
  #     - Restore `Rails.cache.fetch_with_batched_keys` on
  #       `cache_key(:needs_grading)` for the needs-grading buckets
  #       (busted by `Enrollment#clear_needs_grading_count_cache`).
  #     - Submitted/total stay outside the cache — they track enrollment
  #       lifecycle changes the needs-grading key doesn't see.
  #     - Adopt `CourseProxyCache` so visibility/section lookups can be
  #       shared across assignments when the todo list is batched. We
  #       skip it here because this class is instantiated per-assignment
  #       and the cache would never get more than one entry.
  #
  #   See `NeedsGradingCountQueryOptimized` for the shape the optimized
  #   version should take.
  class TeacherTodoMetricsQuery
    VISIBLE_LEVELS = %i[full limited sections sections_limited].freeze
    NOT_EXCUSED = "submissions.excused IS NOT TRUE"

    ZERO_METRICS = {
      on_time_needs_grading_count: 0,
      late_needs_grading_count: 0,
      resubmitted_needs_grading_count: 0,
      submitted_submissions_count: 0,
      total_submissions_count: 0,
    }.freeze

    def initialize(assignment, user)
      @assignment = assignment
      @user = user
    end

    def metrics
      return ZERO_METRICS unless VISIBLE_LEVELS.include?(visibility_level)

      @assignment.shard.activate do
        # 1. Which assignment rows are we counting against?
        #    Checkpointed parents query via children — parent's submission_type
        #    goes nil when children disagree, so it'd fail needs_grading_conditions.
        assignment_ids = @assignment.has_sub_assignments? ? @assignment.sub_assignments.pluck(:id) : [@assignment.id]

        # 2. All active-student submissions for those assignments.
        submissions = active_student_submissions_for(assignment_ids)

        # 3. Section-limited teachers only see their sections.
        submissions = restrict_to_visible_sections(submissions)

        # 4. On moderated assignments, drop what other graders already resolved.
        submissions = exclude_resolved_by_other_graders(submissions)

        # 5. Count the buckets.
        needs_grading = submissions.where(Submission.needs_grading_conditions)

        {
          on_time_needs_grading_count: count_grading_items(needs_grading.merge(Submission.not_late)),
          late_needs_grading_count: count_grading_items(needs_grading.merge(Submission.late)),
          resubmitted_needs_grading_count: count_grading_items(needs_grading.where(grade_matches_current_submission: false)),
          submitted_submissions_count: count_grading_items(submissions.where.not(submission_type: nil).where(NOT_EXCUSED)),
          total_submissions_count: count_grading_items(submissions.where(NOT_EXCUSED)),
        }
      end
    end

    private

    def visibility_level
      @visibility_level ||= @assignment.context.enrollment_visibility_level_for(@user, section_visibilities)
    end

    def section_visibilities
      @section_visibilities ||= @assignment.context.section_visibilities_for(@user)
    end

    def visible_section_ids
      @visible_section_ids ||= section_visibilities.pluck(:course_section_id)
    end

    def active_student_submissions_for(assignment_ids)
      Submission.active
                .where(assignment_id: assignment_ids)
                .joins("INNER JOIN #{Enrollment.quoted_table_name} ON enrollments.user_id = submissions.user_id")
                .where(enrollments: {
                         course_id: @assignment.context_id,
                         type: %w[StudentEnrollment StudentViewEnrollment],
                         workflow_state: "active",
                       })
    end

    def restrict_to_visible_sections(submissions)
      # Moderated path skips section filtering — matches NeedsGradingCountQueryOptimized.
      return submissions if visibility_level == :sections_limited && @assignment.moderated_grading_enabled_and_no_grades_published?
      return submissions unless %i[sections sections_limited].include?(visibility_level)

      submissions.where(enrollments: { course_section_id: visible_section_ids })
    end

    def exclude_resolved_by_other_graders(submissions)
      return submissions unless @assignment.moderated_grading_enabled_and_no_grades_published?

      resolved = submission_ids_resolved_for_grader
      return submissions if resolved.empty?

      submissions.where.not(submissions: { id: resolved })
    end

    # Submission IDs already "resolved" for the calling grader on a moderated
    # assignment before grades are published — i.e. submissions this grader has
    # already provisionally scored, plus submissions that have hit the
    # provisional-grade threshold from other graders. Mirrors the logic in
    # NeedsGradingCountQueryOptimized#needs_moderated_grading_count.
    def submission_ids_resolved_for_grader
      assignment_id = @assignment.id

      # Submissions this user has already provisionally graded with a non-nil score.
      resolved = Submission
                 .joins(:provisional_grades)
                 .where(
                   assignment_id:,
                   moderated_grading_provisional_grades: { final: false, scorer_id: @user.id }
                 )
                 .where.not(moderated_grading_provisional_grades: { score: nil })
                 .pluck(:id)
                 .to_set

      # Threshold is 2 if the student is in the assignment's moderation set, 1 otherwise.
      moderation_student_ids = ModeratedGrading::Selection
                               .where(assignment_id:)
                               .pluck(:student_id)
                               .to_set

      Submission
        .joins(:provisional_grades)
        .where(assignment_id:)
        .where(moderated_grading_provisional_grades: { final: false })
        .where.not(moderated_grading_provisional_grades: { scorer_id: @user.id })
        .group("submissions.id", "submissions.user_id")
        .count
        .each do |(sub_id, user_id), pg_count|
          next if resolved.include?(sub_id)

          threshold = moderation_student_ids.include?(user_id) ? 2 : 1
          resolved << sub_id if pg_count >= threshold
        end

      resolved
    end

    def count_grading_items(submissions)
      submissions.distinct.count("submissions.id")
    end
  end
end
