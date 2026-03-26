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

class AutoGradeOrchestrationService
  MAX_ATTEMPTS = 3

  def initialize(course:, current_user:)
    @course = course
    @current_user = current_user
  end

  def self.extract_essay_text(submission)
    essay_source = submission.extract_text_from_upload? ? submission.extracted_text : submission.body
    ActionView::Base.full_sanitizer.sanitize(essay_source || "")
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

    if auto_grade_result
      progress&.results = auto_grade_result.grade_data
      progress&.message = nil
      progress&.complete!
    end
  end

  def get_grade_data(assignment_text:, root_account_uuid:, submission:, progress:)
    rubric = submission.assignment.rubric_association&.rubric
    raise StandardError, "Missing rubric" unless rubric&.data

    auto_grade_result = AutoGradeResult.find_or_initialize_by(
      submission:,
      attempt: submission.attempt
    )
    missing_criteria = get_criteria_missing_grades(auto_grade_result.grade_data, rubric)

    if missing_criteria.any?
      # filter rubric to only include missing criteria
      relevant_rubric = rubric.data.select { |item| missing_criteria.include?(item[:description]) }

      grade_data = GradeService.new(
        assignment: assignment_text,
        essay: self.class.extract_essay_text(submission),
        rubric: relevant_rubric,
        root_account_uuid:,
        current_user: @current_user
      ).call

      merged_data = merge_new_grade_data_with_existing(grade_data, auto_grade_result.grade_data || [])

      unless get_criteria_missing_grades(merged_data, rubric).empty?
        raise CedarAi::Errors::GraderError, "Number of graded criteria (#{merged_data.length}) is less than the number of rubric criteria (#{rubric.data.length})"
      end

      auto_grade_result.update!(
        root_account_id: submission.course.root_account_id,
        grade_data: merged_data,
        error_message: nil,
        grading_attempts: auto_grade_result.grading_attempts + 1
      )
    end

    auto_grade_result if auto_grade_result.persisted?
  rescue => e
    retryable = e.is_a?(CedarAi::Errors::GraderError)
    handle_grading_failure(
      error_message: "Grading failed: #{e.message}",
      submission:,
      auto_grade_result:,
      progress:,
      retryable:
    )
  end

  def handle_grading_failure(error_message:, submission:, auto_grade_result:, progress:, retryable: true)
    Rails.logger.warn("[AutoGrade] Grading failed for submission #{submission.id}: #{error_message}")

    # this sets the error_message field on the AutoGradeResult if one already exists, since
    # we have the error message in the Progress object and AutoGradeResult cannot be saved
    # with a `nil` grade_data, we explicitly don't save rather than simply letting the save fail.
    record_grading_error(auto_grade_result, error_message, submission.id) if auto_grade_result&.persisted?

    current_attempts = progress&.delayed_job&.attempts&.next
    raise Delayed::RetriableError, error_message if retryable && current_attempts && current_attempts < MAX_ATTEMPTS

    progress_message = retryable ? error_message : I18n.t("An error occurred while grading. Please try again later.")
    fail_progress(progress, progress_message)
  end

  private

  def record_grading_error(auto_grade_result, error_message, submission_id)
    next_attempt = auto_grade_result.grading_attempts + 1
    unless auto_grade_result.update(error_message:, grading_attempts: next_attempt)
      Rails.logger.error("[AutoGrade] Failed to record grading error for submission #{submission_id}")
    end
  end

  def fail_progress(progress, error_message)
    return unless progress

    progress.results = []
    progress.message = error_message
    progress.fail!
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

  def merge_new_grade_data_with_existing(new_data, existing_data = [])
    (existing_data + new_data)
      .group_by { |item| item["description"] }
      .map do |_, items|
        if items.size > 1
          lowest = items.min_by { |i| i.dig("rating", "rating").to_f }
          lowest["rating"]["reasoning"] = [lowest["rating"]["reasoning"], I18n.t("This work sits between two ratings for this criterion. The lower rating was applied for consistency.")].compact.join(" ")
          lowest
        else
          items.first
        end
      end
  end

  def get_criteria_missing_grades(grade_data, rubric)
    return rubric.data.pluck(:description) unless grade_data

    graded_norm = grade_data.pluck("description").map { |d| TextNormalizerHelper.normalize(d) }
    rubric_desc = rubric.data.pluck(:description)
    rubric_desc.reject { |d| graded_norm.include?(TextNormalizerHelper.normalize(d)) }
  end
end
