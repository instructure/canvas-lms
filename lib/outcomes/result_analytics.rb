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
    RollupScore = Struct.new(:outcome, :score, :count, :title, :submitted_at)

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
        outcome = outcome_results.first.learning_outcome
        user_rollup_score = calculate_results(outcome_results, {
          # || 'highest' is for outcomes created prior to this update with no
          # method set so they'll keep their initial behavior
          calculation_method: outcome.calculation_method || "highest",
          calculation_int: outcome.calculation_int
        })
        latest_result = outcome_results.max_by{|result| result.submitted_at.to_i}
        if !latest_result.submitted_at
          # don't pass in a title for comparison if there are no submissions with timestamps
          # otherwise grab the portion of the title that has the assignment/quiz's name
          latest_result.title = nil
        else
          latest_result.title = latest_result.title.split(", ")[1]
        end
        RollupScore.new(outcome, user_rollup_score, outcome_results.size, latest_result.title, latest_result.submitted_at)
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

    def calculate_results(results, method)
      # decaying average is default for new outcomes
      score = case method[:calculation_method]
        when 'decaying_average'
          decaying_average(results, method[:calculation_int])
        when 'n_mastery'
          n_mastery(results, method[:calculation_int])
        when 'latest'
          latest(results)
        when 'highest'
          results.max_by{|result| result.score}.score
      end
      score
    end
    #scoring methods
    def latest(results)
      results.max_by{|result| result.submitted_at.to_i}.score
    end

    def n_mastery(results, n_of_scores)
      return nil if results.length < n_of_scores

      scores = results.map(&:score).sort.last(n_of_scores)
      (scores.sum / scores.length).round(2)
    end

    def decaying_average(results, weight = 75)
      #default grading method with weight of 75 if none selected
      return nil if results.length < 2

      scores = results.sort_by{|result| result.submitted_at.to_i}.map(&:score)
      latestWeighted = scores.pop * (0.01 * weight)
      olderAvgWeighted = (scores.sum / scores.length) * (0.01 * (100 - weight)).round(2)
      latestWeighted + olderAvgWeighted
    end

    class << self
      include ResultAnalytics
    end
  end
end
