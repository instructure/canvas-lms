# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

# This helper provides methods to transform hash data retrieved upon calling
# OutcomesService (OS) authoritative_results endpoint either into:
#
#   - a RollupScores collection via Outcomes::ResultAnalytics
#   - a LearningOutcomeResult collection
#
# It also provides a transformation method for a single OS' AuthoritativeResult
# hash object into a LearningOutcomeResult object

module OutcomesServiceAuthoritativeResultsHelper
  Rollup = Struct.new(:context, :scores)

  # Transforms an OS' hash of AuthoritativeResult collection into a
  # RollupScore collection
  def rollup_scores(authoritative_results, context, outcomes, users, assignments)
    rollup_user_results convert_to_learning_outcome_results(authoritative_results, context, outcomes, users, assignments)
  end

  # Transforms an OS' hash AuthoritativeResult collection into a
  # LearningOutcomeResult collection
  def convert_to_learning_outcome_results(authoritative_results, context = nil, outcomes = nil, users = nil, assignments = nil)
    outcomes_map = outcomes.index_by(&:id)
    user_map = users.index_by(&:uuid)
    assignments_map = assignments.index_by(&:id)
    authoritative_results.each_with_object([]) do |r, all_results|
      result = convert_to_learning_outcome_result_fast(r, context, outcomes_map, user_map, assignments_map)
      all_results.push(result) unless result.nil?
    end
  end

  def convert_to_learning_outcome_result_fast(authoritative_result, context, outcomes, users, assignments)
    assignment = assignments[authoritative_result[:associated_asset_id].to_i]
    outcome = outcomes[authoritative_result[:external_outcome_id].to_i]
    student_user = users[authoritative_result[:user_uuid]]

    root_account = context.root_account
    alignment = ContentTag.new(
      content: assignment,
      tag_type: "learning_outcome",
      learning_outcome_id: authoritative_result[:external_outcome_id],
      context:
    )

    # Retrieves the appropriate proficiency ratings for the outcome at the current context
    proficiency = retrieve_proficiency(context, outcome)

    possible = authoritative_result[:points_possible].to_f
    score = authoritative_result[:points].to_f if authoritative_result[:points]

    # timestamps are defaulted to submitted_at because OS doesn't store any other
    submitted_at = authoritative_result[:submitted_at]

    learning_outcome_result =
      LearningOutcomeResult.new(
        learning_outcome_id: authoritative_result[:external_outcome_id],
        associated_asset: assignment,
        # submission (aka artifact) is not needed for calculating rollup scores
        title: "#{student_user.name}, #{assignment.name}", # title is needed; so we need the assignment (see rollup_score_aggregator_help:latest_result)
        user: student_user,
        user_uuid: student_user.uuid,
        alignment:,
        context:,
        root_account:,
        possible:,
        score:,
        # mastery is computed after the call for calculate_percent!
        original_possible: possible,
        original_score: score,
        created_at: submitted_at,
        updated_at: submitted_at,
        submitted_at:,
        assessed_at: submitted_at
      )

    # Don't call calculate_percent! on the learning_outcome_result. That takes features not yet implemented in
    # new quizzes into account (like outcome score scaling). Instead, percent should always be score / possible
    learning_outcome_result.percent = calculate_percent(score, possible)

    # this implementation ignores mastery as returned by the OS endpoint
    calculate_mastery!(learning_outcome_result, proficiency)

    learning_outcome_result
  end

  # Transforms an OS' hash AuthoritativeResult (AR) object into an
  # instance of LearningOutcomeResult
  def convert_to_learning_outcome_result(authoritative_result)
    outcome = LearningOutcome.find(authoritative_result[:external_outcome_id])
    assignment = Assignment.find(authoritative_result[:associated_asset_id])
    student_user = User.find_by(uuid: authoritative_result[:user_uuid])
    submission = Submission.find_by(user_id: student_user.id, assignment_id: assignment.id)

    context = assignment.context
    root_account = assignment.root_account

    alignment = ContentTag.new(
      content: assignment,
      tag_type: "learning_outcome",
      learning_outcome: outcome,
      context:
    )

    # Retrieves the appropriate proficiency ratings for the outcome at the current context
    proficiency = retrieve_proficiency(context, outcome)

    possible = authoritative_result[:points_possible].to_f
    score = authoritative_result[:points].to_f if authoritative_result[:points]

    # timestamps are defaulted to submitted_at because OS doesn't store any other
    submitted_at = authoritative_result[:submitted_at]

    learning_outcome_result =
      LearningOutcomeResult.new(
        learning_outcome: outcome,
        associated_asset: assignment,
        artifact: submission,
        title: "#{student_user.name}, #{assignment.name}",
        user: student_user,
        user_uuid: student_user.uuid,
        alignment:,
        context:,
        root_account:,
        possible:,
        score:,
        # mastery is computed after the call for calculate_percent!
        original_possible: possible,
        original_score: score,
        created_at: submitted_at,
        updated_at: submitted_at,
        submitted_at:,
        assessed_at: submitted_at
      )

    # Don't call calculate_percent! on the learning_outcome_result. That takes features not yet implemented in
    # new quizzes into account (like outcome score scaling). Instead, percent should always be score / possible
    learning_outcome_result.percent = calculate_percent(score, possible)

    # this implementation ignores mastery as returned by the OS endpoint
    calculate_mastery!(learning_outcome_result, proficiency)

    learning_outcome_result
  end

  def metadata_to_outcome_question_result(learning_outcome_result, question_metadata, attempt_number)
    possible = question_metadata[:points_possible].to_f
    score = question_metadata[:points].to_f if question_metadata[:points]
    submitted_at = learning_outcome_result.submitted_at

    # Retrieves the appropriate proficiency ratings for the outcome at the current context
    proficiency = retrieve_proficiency(learning_outcome_result.context, learning_outcome_result.learning_outcome)

    question_result =
      LearningOutcomeQuestionResult.new(
        learning_outcome_result:,
        learning_outcome: learning_outcome_result.learning_outcome,
        associated_asset_id: question_metadata[:quiz_item_id],
        associated_asset_type: "NewQuizQuestion",
        attempt: attempt_number,
        title: "#{learning_outcome_result.title}: #{question_metadata[:quiz_item_title]}",
        root_account: learning_outcome_result.root_account,
        possible:,
        score:,
        # mastery is computed after the call for calculate_percent!
        original_possible: possible,
        original_score: score,
        created_at: submitted_at,
        updated_at: submitted_at,
        submitted_at:,
        assessed_at: submitted_at
      )

    # We can call calculate_percent! on the question_result because that is always just score / possible
    question_result.calculate_percent! if score

    # This method was modeled after the quiz_outcome_result_builder.create_outcome_question_result
    # In that method, after the call to calculate_percent!, mastery is determined by calling
    # determine_mastery(question_result, alignment). New quizzes does not support alignment mastery, so
    # mastery is determined by the outcome.
    calculate_mastery!(question_result, proficiency)

    question_result
  end

  # Transforms an OS' learning outcome results into a collection of rollups per user
  def outcome_service_results_rollups(outcome_results)
    outcome_results.group_by(&:user_id).map do |_, user_results|
      Rollup.new(user_results.first.user, rollup_user_results(user_results))
    end
  end

  private

  def retrieve_proficiency(context, outcome)
    proficiency ||= outcome unless context&.root_account&.feature_enabled?(:account_level_mastery_scales)
    proficiency ||= context.resolved_outcome_proficiency
    proficiency
  end

  def round(value)
    value&.round(4)
  end

  def calculate_percent(points, points_possible)
    return 0.0 if points_possible.to_f <= 0

    round(points.to_f / points_possible.to_f)
  end

  def calculate_mastery!(result, proficiency)
    if result.percent
      result.original_mastery =
        result.mastery =
          result.percent >= calculate_percent(proficiency.mastery_points, proficiency.points_possible)
    end
  end
end
