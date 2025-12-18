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
    :excused,
    :grade,
    :graded_at,
    :graded_anonymously,
    :grader_id,
    :grade_matches_current_submission,
    :grading_period_id,
    :late_policy_status,
    :published_grade,
    :published_score,
    :posted_at,
    :score,
    :submission_type,
    :submitted_at,
    :updated_at,
    :workflow_state
  )

  WORKFLOW_PRIORITY = {
    pending_review: 4,
    unsubmitted: 3,
    submitted: 2,
    graded: 1
  }.freeze

  def initialize(assignment:, student:)
    super()
    @assignment = assignment
    @student = student
  end

  def call
    return false unless checkpoint_aggregation_supported?(@assignment)

    parent_submission = @assignment.find_or_create_submission(@student)
    child_submissions = @assignment.sub_assignment_submissions.where(user: @student).order(updated_at: :desc).to_a
    return false if parent_submission.nil? || child_submissions.empty?

    aggregate_submission = build_aggregate_submission(child_submissions)
    parent_submission.update_columns(aggregate_submission.to_h)
    true
  end

  private

  def build_aggregate_submission(child_submissions)
    aggregate_submission = AggregateSubmission.new
    aggregate_submission.score = sum(child_submissions, :score)
    aggregate_submission.published_score = sum(child_submissions, :published_score)
    aggregate_submission.updated_at = max(child_submissions, :updated_at)
    most_recently_graded = most_recently_graded(child_submissions)
    if most_recently_graded
      aggregate_submission.graded_anonymously = most_recently_graded.graded_anonymously
      aggregate_submission.graded_at = most_recently_graded.graded_at
      aggregate_submission.grader_id = most_recently_graded.grader_id
    end

    aggregate_submission.excused = child_submissions.any?(&:excused)
    aggregate_submission.grade = grade(child_submissions, aggregate_submission.score)
    aggregate_submission.grading_period_id = shared_attribute(child_submissions, :grading_period_id, nil)
    aggregate_submission.late_policy_status = calculate_late_policy_status(child_submissions)
    aggregate_submission.published_grade = grade(child_submissions, aggregate_submission.published_score)
    aggregate_submission.grade_matches_current_submission = calculate_grade_matches_current_submission(child_submissions)
    aggregate_submission.posted_at = max_if_all_present(child_submissions, :posted_at)
    aggregate_submission.workflow_state = calculate_workflow_state(child_submissions)
    aggregate_submission.submission_type = shared_attribute(child_submissions, :submission_type, nil)
    aggregate_submission.submitted_at = calculate_submitted_at(aggregate_submission, child_submissions) # this calculation for `submitted_at` needs to come after the workflow_state calculation since the updated workflow_state is used
    aggregate_submission
  end

  def calculate_submitted_at(aggregate_submission, child_submissions)
    case aggregate_submission.workflow_state
    when "unsubmitted"
      nil
    when "pending_review", "submitted"
      max(child_submissions, :submitted_at)
    else
      max_if_all_present(child_submissions, :submitted_at)
    end
  end

  def max_if_all_present(child_submissions, field_name)
    child_submissions.all?(&field_name) ? max(child_submissions, field_name) : nil
  end

  def all_nil?(child_submissions, field_name)
    child_submissions.all? { |submission| submission.send(field_name).nil? }
  end

  def all_equal?(child_submissions, field_name, value)
    child_submissions.all? { |submission| submission.send(field_name) == value }
  end

  def grade(child_submissions, score)
    if @assignment.grading_type == "pass_fail"
      return nil if all_nil?(child_submissions, :grade)

      return all_equal?(child_submissions, :grade, "complete") ? "complete" : "incomplete"
    end

    score ? @assignment.score_to_grade(score) : nil
  end

  def calculate_workflow_state(child_submissions)
    if child_submissions.any?(&:needs_grading?)
      # Leaving this here because it looks beyond the workflow_state
      # and reads score and grade_matches_current_submission.
      # We always want to indicate this submission needs grading
      # if any child does.
      return "pending_review"
    end

    child_states = child_submissions.map { |s| s.workflow_state.to_sym }
    child_states.max_by { |state| WORKFLOW_PRIORITY[state] }
  end

  def calculate_grade_matches_current_submission(child_submissions)
    values = child_submissions.pluck(:grade_matches_current_submission)
    values.any?(false) ? false : values.compact.first
  end

  def calculate_late_policy_status(child_submissions)
    values = child_submissions.pluck(:late_policy_status)
    return "late" if any_submission_attribute?(child_submissions, :late?)
    return "missing" if any_submission_attribute?(child_submissions, :missing?)
    return "extended" if any_submission_attribute?(child_submissions, :extended?)
    return "none" if values.include?("none")

    nil
  end

  def any_submission_attribute?(child_submissions, attribute)
    child_submissions.any? { |submission| submission.send(attribute) }
  end

  def shared_attribute(child_submissions, field_name, default)
    values = child_submissions.pluck(field_name)
    (values.uniq.length == 1) ? values.first : default
  end

  def most_recently_graded(child_submissions)
    child_submissions.select(&:graded_at).max_by(&:graded_at)
  end
end
