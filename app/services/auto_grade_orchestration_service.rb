# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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
#

class CedarAIGraderError < StandardError; end

class AutoGradeOrchestrationService
  MAX_ATTEMPTS = 3

  def initialize(course:)
    @course = course
  end

  def auto_grade_in_background(submission:)
    user = submission.user

    progress = @course.progresses.create!(tag: "auto_grade_submission", user:)
    singleton_key = "Course#run_auto_grader:#{submission.global_id}:#{submission.attempt}"
    n_strand_key = ["Course#run_auto_grader", @course.global_root_account_id]

    progress.process_job(
      self,
      :run_auto_grader,
      {
        priority: Delayed::HIGH_PRIORITY,
        n_strand: n_strand_key,
        singleton: singleton_key,
        on_conflict: :use_earliest,
        preserve_method_args: true,
        max_attempts: MAX_ATTEMPTS
      },
      progress,
      submission
    )
    handle_existing_progress(progress, singleton_key)
  end

  def run_auto_grader(progress, submission)
    assignment = submission.assignment
    assignment_text = ActionView::Base.full_sanitizer.sanitize(assignment.description || "")
    root_account_uuid = submission.course.account.root_account.uuid

    auto_grade_result = get_grade_data(assignment_text:, root_account_uuid:, submission:, progress:)
    auto_grade_result = generate_comments(assignment_text:, root_account_uuid:, submission:, auto_grade_result:, progress:)

    progress&.results = auto_grade_result.grade_data
    progress&.message = nil
    progress&.complete!
  end

  def get_grade_data(assignment_text:, root_account_uuid:, submission:, progress:)
    essay = ActionView::Base.full_sanitizer.sanitize(submission.body || "")
    rubric = submission.assignment.rubric_association&.rubric
    raise StandardError, "Missing rubric" unless rubric&.data

    auto_grade_result = AutoGradeResult.find_or_initialize_by(
      submission:,
      attempt: submission.attempt
    )
    missing_criteria = get_criteria_missing_grades(auto_grade_result.grade_data, rubric)

    unless missing_criteria.empty?
      # filter rubric to only include missing criteria
      relevant_rubric = rubric.data.select { |item| missing_criteria.include?(item[:description]) }

      grade_data = GradeService.new(
        assignment: assignment_text,
        essay:,
        rubric: relevant_rubric,
        root_account_uuid:
      ).call

      # Merge new grade data with existing data
      existing_data = auto_grade_result.grade_data || []
      merged_data = existing_data + grade_data

      auto_grade_result.update!(
        root_account_id: submission.course.root_account_id,
        grade_data: merged_data,
        error_message: nil,
        grading_attempts: auto_grade_result.grading_attempts + 1
      )

      unless get_criteria_missing_grades(auto_grade_result.grade_data, rubric).empty?
        raise CedarAIGraderError, "Number of graded criteria (#{merged_data.length}) is less than the number of rubric criteria (#{rubric.data.length})"
      end
    end

    auto_grade_result
  rescue => e
    Rails.logger.warn("[AutoGrade] Grading failed for submission #{submission.id}: #{e.message}")
    retryable = e.is_a?(CedarAIGraderError)
    handle_grading_failure(
      error_message: "Grading failed: #{e.message}",
      submission:,
      auto_grade_result:,
      progress:,
      retryable:
    )
  end

  def generate_comments(assignment_text:, root_account_uuid:, submission:, auto_grade_result:, progress:)
    rubric = submission.assignment.rubric_association&.rubric
    missing_criteria = get_criteria_missing_comments(auto_grade_result.grade_data, rubric)

    unless missing_criteria.empty?
      # filter grade_data to only include missing criteria
      relevant_grade_data = auto_grade_result.grade_data.select { |item| missing_criteria.include?(item["description"]) }

      grade_data_with_comments = CommentsService.new(
        assignment: assignment_text,
        grade_data: relevant_grade_data,
        root_account_uuid:
      ).call

      # Merge new grade data with existing data
      existing_data = auto_grade_result.grade_data.reject { |item| missing_criteria.include?(item["description"]) }
      merged_data = existing_data + grade_data_with_comments

      auto_grade_result.update!(
        root_account_id: submission.course.root_account_id,
        grade_data: merged_data,
        error_message: nil,
        grading_attempts: auto_grade_result.grading_attempts + 1
      )

      unless get_criteria_missing_comments(merged_data, rubric).empty?
        raise CedarAIGraderError, "Number of comments (#{merged_data.length}) is less than the number of rubric criteria (#{rubric.data.length})"
      end
    end

    auto_grade_result
  rescue => e
    Rails.logger.warn("[AutoGrade] Grading failed for submission #{submission.id}: #{e.message}")
    retryable = e.is_a?(CedarAIGraderError)
    handle_grading_failure(
      error_message: "Grading failed: #{e.message}",
      submission:,
      auto_grade_result:,
      progress:,
      retryable:
    )
  end

  def handle_grading_failure(error_message:, submission:, auto_grade_result:, progress:, retryable: true)
    autograde_error_handling(submission, auto_grade_result, progress, error_message)
    current_attempts = progress&.delayed_job&.attempts&.+ 1

    if retryable && current_attempts < MAX_ATTEMPTS
      raise Delayed::RetriableError, error_message
    end

    progress&.results = []
    progress&.message = I18n.t("Grading failed. Please try again later or grade manually.")
    progress&.complete!
  end

  def autograde_error_handling(submission, auto_grade_result, progress, error_message)
    auto_grade_result ||= AutoGradeResult.find_or_initialize_by(
      submission:,
      attempt: submission.attempt
    )

    auto_grade_result&.update!(
      root_account_id: submission.course.root_account_id,
      grade_data: auto_grade_result.grade_data,
      error_message:,
      grading_attempts: auto_grade_result.grading_attempts + 1
    )

    if progress
      progress.results = []
      progress.message = error_message
    end
  rescue => e
    Rails.logger.error("[AutoGrade] Failed to record grading error: #{e.message}")
  end

  def handle_existing_progress(progress, singleton_key)
    matching_jobs = Delayed::Job.where(singleton: singleton_key, locked_at: nil)
    existing_progress = Progress.where(delayed_job_id: matching_jobs.pluck(:id))
                                .where.not(id: progress.id)
                                .first
    if existing_progress
      progress.update!(
        workflow_state: "failed",
        completion: 0,
        message: "Skipped: a similar job is already queued or running."
      )
      return existing_progress
    end

    progress
  end

  def get_criteria_missing_grades(grade_data, rubric)
    return rubric.data.pluck(:description) unless grade_data

    graded_criteria = grade_data.pluck("description")
    all_criteria = rubric.data.pluck(:description)
    all_criteria - graded_criteria
  end

  def get_criteria_missing_comments(grade_data, rubric)
    return rubric.data.pluck(:description) unless grade_data

    grade_data.reject { |item| item["comments"] }
              .pluck("description")
  end
end
