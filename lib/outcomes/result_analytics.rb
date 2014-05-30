#
# Copyright (C) 2013 Instructure, Inc.
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
  module ResultAnalytics

    Rollup = Struct.new(:context, :scores)
    RollupScore = Struct.new(:outcome, :score, :count)

    # Public: Queries learning_outcome_results for rollup.
    #
    # opts - The options for the query. In a later version of ruby, these would
    #        be named parameters.
    #        :users    - The users to lookup results for (required)
    #        :context  - The context to lookup results for (required)
    #        :outcomes - The outcomes to lookup results for (required)
    #
    # Returns a relation of the results, suitably ordered.
    def find_outcome_results(opts)
      required_opts = [:users, :context, :outcomes]
      required_opts.each { |p| raise "#{p} option is required" unless opts[p] }
      users, context, outcomes = opts.values_at(*required_opts)

      order_results_for_rollup LearningOutcomeResult.where(
        context_code:        context.asset_string,
        user_id:             users.map(&:id),
        learning_outcome_id: outcomes.map(&:id),
      )
    end

    # Internal: Add an order clause to a relation so results are returned in an
    # order suitable for rollup calculations.
    #
    # relation - The relation to add an order clause to.
    #
    # Returns the resulting relation
    def order_results_for_rollup(relation)
      relation.order(:user_id, :learning_outcome_id)
    end

    # Public: Generates a rollup of each outcome result for each user.
    #
    # results - An Enumeration of properly sorted LearningOutcomeResult objects.
    #           The results should be sorted by user id and then by outcome id.
    #
    # users - (Optional) Ensure rollups are included for users in this list.
    #         A listed user with no results will have an empty score array.
    #
    # Returns an Array of Rollup objects.
    def outcome_results_rollups(results, users=[])
      rollups = results.chunk(&:user_id).map do |_, user_results|
        Rollup.new(user_results.first.user, rollup_user_results(user_results))
      end
      add_missing_user_rollups(rollups, users)
    end


    # Public: Calculates an average rollup for the specified results
    #
    # results - An Enumeration of properly sorted LearningOutcomeResult objects.
    # context - The context to use for the resulting rollup.
    #
    # Returns a Rollup.
    def aggregate_outcome_results_rollup(results, context)
      rollups = outcome_results_rollups(results)
      rollup_scores = rollups.map(&:scores).flatten
      outcome_scores = rollup_scores.group_by(&:outcome)

      aggregate_scores = outcome_scores.map do |outcome, scores|
        aggregate_score = scores.map(&:score).sum.to_f / scores.size
        RollupScore.new(outcome, aggregate_score, scores.size)
      end
      Rollup.new(context, aggregate_scores)
    end

    # Internal: Generates a rollup of the outcome results, Assuming all the
    # results are for the same user.
    #
    # user_results - An Enumeration of LearningOutcomeResult objects for a user
    #                sorted by outcome id.
    #
    # Returns an Array of RollupScore objects
    def rollup_user_results(user_results)
      outcome_scores = user_results.chunk(&:learning_outcome_id).map do |_, outcome_results|
        user_rollup_score = outcome_results.map(&:score).max
        RollupScore.new(outcome_results.first.learning_outcome, user_rollup_score, outcome_results.size)
      end
    end

    # Internal: Adds rollups rows for users that did not have any results
    #
    # rollups - The list of rollup objects based on existing results.
    # users   - The list of User objects that should have results.
    #
    # Returns the modified rollups list. Users without rollups will have a
    #   rollup row with an empty scores array.
    def add_missing_user_rollups(rollups, users)
      missing_users = users - rollups.map(&:context)
      rollups + missing_users.map { |u| Rollup.new(u, []) }
    end

    class << self
      include ResultAnalytics
    end
  end
end
