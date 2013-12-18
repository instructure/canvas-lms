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

      # TODO: need to worry about user sharding
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
    # Returns a hash of the results:
    #   {
    #      user: the associated user object,
    #      scores: [{
    #        outcome: the outcome object
    #        score: the rollup score for all the user's results for the outcome.
    #      }, ..., repeated for each outcome, ...]
    #   }
    def rollup_results(results)
      results.chunk(&:user_id).map do |_, user_results|
        {
          user: user_results.first.user,
          scores: rollup_user_results(user_results),
        }
      end
    end

    # Internal: Generates a rollup of the outcome results, Assuming all the
    # results are for the same user.
    #
    # user_results - An Enumeration of LearningOutcomeResult objects for a user
    #                sorted by outcome id.
    #
    # Returns a hash of the rollup:
    #   {
    #     outcome: the outcome object
    #     score: the rolled up score for all the results.
    #   }
    def rollup_user_results(user_results)
      outcome_scores = user_results.chunk(&:learning_outcome_id).map do |_, outcome_results|
        {
          outcome: outcome_results.first.learning_outcome,
          score: outcome_results.map(&:score).max
        }
      end
    end

    class << self
      include ResultAnalytics
    end
  end
end
