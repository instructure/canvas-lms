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

module Outcomes
  # Common service containing shared logic for outcome rollup calculations.
  # This service provides reusable methods for fetching results, combining them,
  # and generating rollup data that can be used by different rollup calculation services.
  class RollupCommonService < ApplicationService
    include Outcomes::ResultAnalytics
    include OutcomesServiceAuthoritativeResultsHelper
    include CanvasOutcomesHelper

    # Fetches Canvas learning outcome results
    # @param course [Course] the course context
    # @param users [Array<User>] the users to fetch results for
    # @param outcomes [ActiveRecord::Relation<LearningOutcome>, Array<LearningOutcome>, nil]
    #        the outcomes to fetch results for (nil for all course outcomes)
    # @return [ActiveRecord::Relation<LearningOutcomeResult>]
    def fetch_canvas_results(course:, users:, outcomes: nil)
      outcomes ||= course.linked_learning_outcomes

      results = LearningOutcomeResult
                .active
                .with_active_link
                .where(
                  context_code: course.asset_string,
                  user_id: users.map(&:id),
                  learning_outcome_id: outcomes.map(&:id),
                  hidden: false
                )
      order_results_for_rollup(results)
    end

    # Fetches Outcomes Service results for New Quizzes
    # @param course [Course] the course context
    # @param users [Array<User>] the users to fetch results for
    # @param outcomes [ActiveRecord::Relation<LearningOutcome>, Array<LearningOutcome>, nil]
    #        the outcomes to fetch results for (nil for all course outcomes)
    # @param assignments [ActiveRecord::Relation<Assignment>, nil]
    #        quiz assignments to fetch results from (nil to fetch all quiz assignments)
    # @return [Array<LearningOutcomeResult>]
    def fetch_outcomes_service_results(course:, users:, outcomes: nil, assignments: nil)
      assignments ||= Assignment.active.where(context: course).quiz_lti
      return [] if assignments.blank?

      outcomes ||= course.linked_learning_outcomes
      return [] if outcomes.blank?

      os_results_json = find_outcomes_service_outcome_results(
        users:,
        context: course,
        outcomes:,
        assignments:
      )
      return [] if os_results_json.blank?

      handle_outcomes_service_results(
        os_results_json,
        course,
        outcomes,
        users,
        assignments
      )
    end

    # Combines and deduplicates results from multiple sources
    # @param canvas_results [ActiveRecord::Relation<LearningOutcomeResult>, Array<LearningOutcomeResult>]
    # @param outcomes_results [Array<LearningOutcomeResult>]
    # @return [Array<LearningOutcomeResult>]
    def combine_results(canvas_results = [], outcomes_results = [])
      return canvas_results.to_a if outcomes_results.blank?
      return outcomes_results if canvas_results.blank?

      all_results = canvas_results.to_a + outcomes_results

      all_results.uniq do |result|
        [
          result.learning_outcome_id,
          result.user_uuid || result.user_id,
          result.associated_asset_id || result.artifact_id
        ]
      end
    end

    # Generates rollup data from learning outcome results
    # @param results [Array<LearningOutcomeResult>] the results to generate rollups from
    # @param users [Array<User>] the users to generate rollups for
    # @param context [Course] the course context
    # @return [Array<Rollup>] array of rollup objects with scores
    def generate_rollups(results, users, context)
      return [] if results.empty?

      ActiveRecord::Associations.preload(results, :learning_outcome)
      outcome_results_rollups(
        results:,
        users:,
        context:
      )
    end

    # Builds database rows from rollup data
    # @param rollup [Rollup] the rollup data containing scores
    # @param course [Course] the course context
    # @param user [User] the user the rollup is for
    # @return [Array<Hash>] array of hashes ready for database insertion
    def build_rollup_rows(rollup, course, user)
      rollup.scores.filter_map do |score|
        # Skip scores that are nil (e.g., from n_mastery calculations with insufficient attempts)
        next if score.score.nil?

        {
          root_account_id: course.root_account_id,
          course_id: course.id,
          user_id: user.id,
          outcome_id: score.outcome.id,
          calculation_method: score.outcome.calculation_method,
          aggregate_score: score.score,
          submitted_at: score.submitted_at,
          title: score.title,
          hide_points: score.hide_points || false,
          results_count: score.count,
          workflow_state: "active",
          last_calculated_at: Time.current,
        }
      end
    end
  end
end
