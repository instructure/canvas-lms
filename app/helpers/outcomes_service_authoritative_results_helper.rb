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

# This helper provides methods to transform JSON data retrieved upon calling
# OutcomesService (OS) authoritative_results endpoint either into:
#
#   - a RollupScores collection via Outcomes::ResultAnalytics
#   - a LearningOutcomeResult collection
#
# It also provides a transformation method for a single OS' AuthoritativeResult
# JSON object into a LearningOutcomeResult object

module OutcomesServiceAuthoritativeResultsHelper
  include Outcomes::ResultAnalytics

  # Transforms an OS' JSON AuthoritativeResult collection into a
  # RollupScore collection
  def json_to_rollup_scores(authoritative_results)
    rollup_user_results json_to_outcome_results(authoritative_results)
  end

  # Transforms an OS' JSON AuthoritativeResult collection into a
  # LearningOutcomeResult collection
  def json_to_outcome_results(authoritative_results)
    JSON.parse(authoritative_results).deep_symbolize_keys[:results].map do |r|
      json_to_outcome_result(r)
    end
  end

  # Transforms an OS' JSON AuthoritativeResult (AR) object into an
  # instance of LearningOutcomeResult
  def json_to_outcome_result(authoritative_result)
    outcome = LearningOutcome.find(authoritative_result[:external_outcome_id])
    assignment = Assignment.find(authoritative_result[:associated_asset_id])
    user = User.find_by(uuid: authoritative_result[:user_uuid])
    submission = Submission.find_by(user_id: user.id, assignment_id: assignment.id)

    context = assignment.context
    root_account = assignment.root_account

    alignment = ContentTag.new(
      content: assignment,
      tag_type: "learning_outcome",
      learning_outcome: outcome,
      context: context
    )

    # Retrieves the appropriate proficiency ratings for the outcome at the current context
    proficiency(context, outcome)

    possible = authoritative_result[:points_possible].to_f
    score = authoritative_result[:points].to_f if authoritative_result[:points]

    # timestamps are defaulted to submitted_at because OS doesn't store any other
    submitted_at = authoritative_result[:submitted_at]

    learning_outcome_result =
      LearningOutcomeResult.new(
        learning_outcome: outcome,
        associated_asset: assignment,
        artifact: submission,
        title: "#{user.name}, #{assignment.name}",
        user: user,
        user_uuid: user.uuid,
        alignment: alignment,
        context: context,
        root_account: root_account,
        possible: possible,
        score: score,
        # mastery is computed after the call for calculate_percent!
        original_possible: possible,
        original_score: score,
        created_at: submitted_at,
        updated_at: submitted_at,
        submitted_at: submitted_at,
        assessed_at: submitted_at
      )

    learning_outcome_result.calculate_percent!

    # this implementation ignores mastery as returned by the OS endpoint
    if score
      learning_outcome_result.original_mastery =
        learning_outcome_result.mastery =
          score >= @proficiency.mastery_points
    end

    learning_outcome_result
  end

  # Transforms an OS' learning outcome results into a collection of rollups per user
  def outcome_service_results_rollups(outcome_results)
    outcome_results.group_by(&:user_id).map do |_, user_results|
      Rollup.new(user_results.first.user, rollup_user_results(user_results))
    end
  end

  private

  def proficiency(context, outcome)
    @proficiency ||= outcome unless context&.root_account&.feature_enabled?(:account_level_mastery_scales)
    @proficiency ||= context.resolved_outcome_proficiency
    @proficiency
  end
end
