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

class Checkpoints::SubmissionAggregatorService < Checkpoints::AggregatorService
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
    return false unless checkpoint_aggregation_supported?(@assignment)

    parent_submission = @assignment.submissions.find_by(user: @student)
    submissions = @assignment.sub_assignment_submissions.where(user: @student).order(updated_at: :desc).to_a
    return false if parent_submission.nil? || submissions.empty?

    aggregate_submission = build_aggregate_submission(submissions)
    parent_submission.update_columns(aggregate_submission.to_h)
    true
  end

  private

  def build_aggregate_submission(submissions)
    submission = AggregateSubmission.new
    submission.score = sum(submissions, :score)
    submission.published_score = sum(submissions, :published_score)
    submission.updated_at = max(submissions, :updated_at)

    most_recently_graded = most_recently_graded(submissions)
    if most_recently_graded
      submission.graded_anonymously = most_recently_graded.graded_anonymously
      submission.graded_at = most_recently_graded.graded_at
      submission.grader_id = most_recently_graded.grader_id
    end

    submission.grade = grade(submission.score)
    submission.published_grade = grade(submission.published_score)
    submission.grade_matches_current_submission = calculate_grade_matches_current_submission(submissions)
    submission.posted_at = max_if_all_present(submissions, :posted_at)
    submission.workflow_state = shared_attribute(submissions, :workflow_state, "unsubmitted")
    submission.submission_type = shared_attribute(submissions, :submission_type, nil)
    submission.submitted_at = max_if_all_present(submissions, :submitted_at)
    submission
  end

  def max_if_all_present(submissions, field_name)
    submissions.all?(&field_name) ? max(submissions, field_name) : nil
  end

  def grade(score)
    score ? @assignment.score_to_grade(score) : nil
  end

  def calculate_grade_matches_current_submission(submissions)
    values = submissions.pluck(:grade_matches_current_submission)
    values.any?(false) ? false : values.compact.first
  end

  def shared_attribute(submissions, field_name, default)
    values = submissions.pluck(field_name)
    (values.uniq.length == 1) ? values.first : default
  end

  def most_recently_graded(submissions)
    submissions.select(&:graded_at).max_by(&:graded_at)
  end
end
