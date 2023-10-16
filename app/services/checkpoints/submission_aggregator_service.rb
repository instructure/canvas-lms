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

class Checkpoints::SubmissionAggregatorService < ApplicationService
  AggregateSubmission = Struct.new(
    :grade,
    :graded_at,
    :graded_anonymously,
    :grader_id,
    :grade_matches_current_submission,
    :published_grade,
    :published_score,
    :posted_at,
    :score,
    :submission_type,
    :submitted_at,
    :updated_at,
    :workflow_state
  )

  def initialize(assignment:, student:)
    super()
    @assignment = assignment
    @student = student
  end

  def call
    return false unless checkpoint_aggregation_supported?

    parent_submission = @assignment.submissions.find_by(user: @student)
    submissions = @assignment.checkpoint_submissions.where(user: @student).order(updated_at: :desc).to_a
    return false if parent_submission.nil? || submissions.empty?

    aggregate_submission = build_aggregate_submission(submissions)
    handle_grade_attributes(aggregate_submission, submissions)
    handle_workflow_state(aggregate_submission, submissions)
    handle_submitted_attributes(aggregate_submission, submissions)
    parent_submission.update_columns(aggregate_submission.to_h)
    true
  end

  private

  def build_aggregate_submission(submissions)
    submissions.each_with_object(AggregateSubmission.new) do |submission, aggregate_submission|
      aggregate_submission.score = calculate_score(submission, aggregate_submission) unless submission.excused?
      aggregate_submission.published_score = calculate_published_score(submission, aggregate_submission) unless submission.excused?
      aggregate_submission.updated_at = calculate_updated_at(submission, aggregate_submission)

      most_recently_graded = most_recently_graded(submission, aggregate_submission)
      aggregate_submission.graded_anonymously = most_recently_graded.graded_anonymously
      aggregate_submission.graded_at = most_recently_graded.graded_at
      aggregate_submission.grader_id = most_recently_graded.grader_id
    end
  end

  def calculate_grade_matches_current_submission(submissions)
    values = submissions.pluck(:grade_matches_current_submission)
    values.any?(false) ? false : values.compact.first
  end

  def calculate_published_score(submission, aggregate_submission)
    sum(submission.published_score, aggregate_submission.published_score)
  end

  def calculate_score(submission, aggregate_submission)
    sum(submission.score, aggregate_submission.score)
  end

  def calculate_submission_type(submissions)
    types = submissions.pluck(:submission_type)
    return types.first if types.uniq.length == 1

    nil
  end

  def calculate_submitted_at(submissions)
    submitted_ats = submissions.pluck(:submitted_at)
    submitted_ats.any?(nil) ? nil : submitted_ats.max
  end

  def calculate_updated_at(submission, aggregate_submission)
    [submission.updated_at, aggregate_submission.updated_at].compact.max
  end

  def calculate_workflow_state(submissions)
    workflows = submissions.pluck(:workflow_state)
    return workflows.first if workflows.uniq.length == 1

    "unsubmitted"
  end

  def handle_grade_attributes(aggregate_submission, submissions)
    if aggregate_submission.score
      aggregate_submission.grade = @assignment.score_to_grade(aggregate_submission.score)
    end

    if aggregate_submission.published_score
      aggregate_submission.published_grade = @assignment.score_to_grade(aggregate_submission.published_score)
    end

    aggregate_submission.grade_matches_current_submission = calculate_grade_matches_current_submission(submissions)

    if submissions.all?(&:posted_at)
      aggregate_submission.posted_at = submissions.pluck(:posted_at).max
    end

    true
  end

  def handle_submitted_attributes(aggregate_submission, submissions)
    aggregate_submission.submission_type = calculate_submission_type(submissions)
    aggregate_submission.submitted_at = calculate_submitted_at(submissions)
    true
  end

  def handle_workflow_state(aggregate_submission, submissions)
    aggregate_submission.workflow_state = calculate_workflow_state(submissions)
    true
  end

  def most_recently_graded(submission, aggregate_submission)
    graded_submissions = [submission, aggregate_submission].select(&:graded_at)
    graded_submissions.empty? ? aggregate_submission : graded_submissions.max_by(&:graded_at)
  end

  def sum(score, running_total)
    scores = [score, running_total].compact
    scores.empty? ? nil : scores.sum
  end

  def checkpoint_aggregation_supported?
    @assignment.present? &&
      @assignment.active? &&
      @assignment.checkpointed? &&
      @assignment.root_account&.feature_enabled?(:discussion_checkpoints)
  end
end
