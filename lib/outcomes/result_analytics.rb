# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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
    include CanvasOutcomesHelper
    include OutcomeResultResolverHelper

    Rollup = Struct.new(:context, :scores)
    Result = Struct.new(:learning_outcome, :score, :count, :hide_points) # rubocop:disable Lint/StructNewOverride

    # Public: Queries learning_outcome_results for rollup.
    #
    # user - User requesting results.
    # opts - The options for the query. In a later version of ruby, these would
    #        be named parameters.
    #        :users    - The users to lookup results for (required)
    #        :context  - The context to lookup results for (required)
    #        :outcomes - The outcomes to lookup results for (required)
    #
    # Returns a relation of the results, suitably ordered.
    def find_outcome_results(user, opts)
      required_opts = %i[users context outcomes]
      required_opts.each { |p| raise "#{p} option is required" unless opts[p] }
      users, context, outcomes = opts.values_at(*required_opts)
      results = LearningOutcomeResult.active.with_active_link.where(
        context_code: context.asset_string,
        user_id: users.map(&:id),
        learning_outcome_id: outcomes.map(&:id)
      )
      # muted associations is applied to remove assignments that students
      # are not yet allowed to view:
      # Assignment Grades have not be posted yet (i.e. Submission.posted_at = nil)
      # PostPolicy.post_manually is false & the submission is not posted
      # Assignment grading_type is not_graded
      # see result_analytics_spec.rb for more details around what is excluded/included
      unless context.grants_any_right?(user, :manage_grades, :view_all_grades)
        results = results.exclude_muted_associations
      end
      # LOR hidden is populated for non-scoring rubrics only which is set
      # by checking Don't post Outcomes results to Learning Mastery Gradebook`
      # when adding a rubric to an assignment
      # also see rubric_assessment.create_outcome_result
      unless opts[:include_hidden]
        results = results.where(hidden: false)
      end
      order_results_for_rollup results
    end

    # Public: Queries Outcome Service to return for outcome results.
    #
    # user - User requesting results.
    # opts - The options for the query. In a later version of ruby, these would
    #        be named parameters.
    #        :users    - The users to lookup results for (required)
    #        :context  - The context to lookup results for (required)
    #        :outcomes - The outcomes to lookup results for (required)
    #        :assignments - The assignments to lookup results for (required)
    #
    # Returns json object
    def find_outcomes_service_outcome_results(opts)
      required_opts = %i[users context outcomes assignments]
      required_opts.each { |p| raise "#{p} option is required" unless opts[p] }
      users, context, outcomes, assignments = opts.values_at(*required_opts)
      user_uuids = users.pluck(:uuid).join(",")
      assignment_ids = assignments.pluck(:id).join(",")

      outcome_ids = outcomes.pluck(:id).join(",")
      get_lmgb_results(context, assignment_ids, "canvas.assignment.quizzes", outcome_ids, user_uuids)
    end

    # Converts json results from OS API to LearningOutcomeResults and removes duplicate result data
    # Tech debt: decouple conversion and removing duplicates
    #
    # results - OS api results json (see get_lmgb_results)
    # context - results context (aka current course)
    #
    # Returns an array of LearningOutcomeResult objects
    def handle_outcomes_service_results(results, context, outcomes, users, assignments)
      # if results are nil - FF is turned off for the given context
      # if results are empty - no results were matched
      if results.blank?
        Rails.logger.warn("No Outcome Service outcome results found for context: #{context.uuid}")
        return nil
      end
      # return resolved results list of Rollup objects
      resolve_outcome_results(results, context, outcomes, users, assignments)
    end

    # Internal: Add an order clause to a relation so results are returned in an
    # order suitable for rollup calculations.
    #
    # relation - The relation to add an order clause to.
    #
    # Returns the resulting relation
    def order_results_for_rollup(relation)
      relation.joins(:user)
              .order(User.sortable_name_order_by_clause)
              .order("users.id ASC, learning_outcome_results.learning_outcome_id ASC, learning_outcome_results.id ASC")
    end

    # Public: Generates a rollup of each outcome result for each user.
    #
    # results - An Enumeration of properly sorted LearningOutcomeResult objects.
    #           The results should be sorted by user id and then by outcome id.
    #
    # users - (Optional) Ensure rollups are included for users in this list.
    #         A listed user with no results will have an empty score array.
    #
    # excludes - (Optional) Specify additional values to exclude. "missing_user_rollups" excludes
    #            rollups for users without results.
    #
    # context - (Optional) The current context making the function call which will be used in
    #            determining the current_method chosen for calculating rollups.
    #
    # Returns an Array of Rollup objects.
    def outcome_results_rollups(results:, users: [], excludes: [], context: nil)
      rollups = results.group_by(&:user_id).map do |_, user_results|
        Rollup.new(user_results.first.user, rollup_user_results(user_results, context))
      end
      if excludes.include? "missing_user_rollups"
        rollups
      else
        add_missing_user_rollups(rollups, users)
      end
    end

    # Public: Retrieves rollup data from the OutcomeRollup table.
    #
    # users - The users to lookup rollup data for (required)
    # context - The context to lookup rollup data for (required)
    # outcomes - (Optional) The outcomes to lookup rollup data for
    # excludes - (Optional) Specify additional values to exclude. "missing_user_rollups" excludes
    #            rollups for users without results.
    #
    # Returns an Array of Rollup objects in the same format as outcome_results_rollups.
    def stored_outcome_rollups(users:, context:, outcomes: nil, excludes: [])
      rollup_records = OutcomeRollup.active
                                    .where(course_id: context.id, user_id: users.map(&:id))
      rollup_records = rollup_records.where(outcome_id: outcomes.map(&:id)) if outcomes.present?
      rollup_records = rollup_records.preload(:user, :outcome)

      rollups = rollup_records.group_by(&:user_id).map do |_, user_rollups|
        user = user_rollups.first.user
        scores = user_rollups.map do |rollup_record|
          # Use RollupScore in stored mode for pre-calculated rollups
          RollupScore.new(
            opts: {
              stored: true,
              outcome: rollup_record.outcome,
              score: rollup_record.aggregate_score,
              count: rollup_record.results_count,
              hide_points: rollup_record.hide_points,
              title: rollup_record.title,
              submitted_at: rollup_record.submitted_at
            }
          )
        end

        Rollup.new(user, scores)
      end

      if excludes.include? "missing_user_rollups"
        rollups
      else
        add_missing_user_rollups(rollups, users)
      end
    end

    # Public: Calculates an average rollup for the specified results
    #
    # results - An Enumeration of properly sorted LearningOutcomeResult objects.
    # context - The context to use for the resulting rollup.
    #
    # Returns a Rollup.
    def aggregate_outcome_results_rollup(results, context, stat = "mean")
      rollups = outcome_results_rollups(results:, context:)
      rollup_scores = rollups.map(&:scores).flatten
      outcome_results = rollup_scores.group_by(&:outcome).values
      aggregate_results = outcome_results.map do |scores|
        scores.map { |score| Result.new(score.outcome, score.score, score.count, score.hide_points) }
      end
      opts = { aggregate_score: true, aggregate_stat: stat, **mastery_scale_opts(context) }
      aggregate_rollups = aggregate_results.map do |result|
        RollupScore.new(outcome_results: result, opts:)
      end
      Rollup.new(context, aggregate_rollups)
    end

    # Internal: Generates a rollup of the outcome results, Assuming all the
    # results are for the same user.
    #
    # user_results - An Enumeration of LearningOutcomeResult objects for a user
    #                sorted by outcome id.
    #
    # Returns an Array of RollupScore objects
    def rollup_user_results(user_results, context = nil)
      filtered_results = user_results.reject { |r| r.score.nil? }
      opts = mastery_scale_opts(context)
      filtered_results.group_by(&:learning_outcome_id).map do |_, outcome_results|
        RollupScore.new(outcome_results:, opts:)
      end
    end

    def mastery_scale_opts(context)
      return {} unless context.is_a?(Course) && context.root_account.feature_enabled?(:account_level_mastery_scales)

      @mastery_scale_opts ||= {}
      @mastery_scale_opts[context.asset_string] ||= begin
        method = context.resolved_outcome_calculation_method
        mastery_scale = context.resolved_outcome_proficiency
        {
          calculation_method: method&.calculation_method,
          calculation_int: method&.calculation_int,
          points_possible: mastery_scale&.points_possible,
          mastery_points: mastery_scale&.mastery_points,
          ratings: mastery_scale&.ratings_hash,
          proficiency_context_type: mastery_scale&.context_type,
          proficiency_context_id: mastery_scale&.context_id&.to_s
        }
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

    # Public: Gets rating percents for outcomes based on rollup
    #
    # Returns a hash of outcome id to array of rating percents
    def rating_percents(rollups, context: nil)
      counts = {}
      outcome_proficiency_ratings = if context&.root_account&.feature_enabled?(:account_level_mastery_scales)
                                      context.resolved_outcome_proficiency&.ratings_hash
                                    end
      rollups.each do |rollup|
        rollup.scores.each do |score|
          next unless score.score

          outcome = score.outcome
          next unless outcome

          ratings = outcome_proficiency_ratings || outcome.rubric_criterion[:ratings]
          next unless ratings

          counts[outcome.id] = Array.new(ratings.length, 0) unless counts[outcome.id]
          idx = ratings.find_index { |rating| rating[:points] <= score.score }
          counts[outcome.id][idx] = counts[outcome.id][idx] + 1 if idx
        end
      end
      counts.each { |k, v| counts[k] = to_percents(v) }
      counts
    end

    def to_percents(count_arr)
      total = count_arr.sum
      return count_arr if total.zero?

      count_arr.map { |v| (100.0 * v / total).round }
    end

    # Public: Calculates distribution counts for each outcome across rollups
    #
    # rollups - Array of Rollup objects
    # outcomes - Array of LearningOutcome objects
    # context - Course or Account context
    #
    # Returns a hash of outcome_id => distribution data with counts and student_ids per rating
    def mastery_distributions(rollups:, outcomes:, context: nil, opts: {})
      outcome_proficiency_ratings = if context&.root_account&.feature_enabled?(:account_level_mastery_scales)
                                      context.resolved_outcome_proficiency.ratings_hash
                                    end

      distributions = {}

      outcomes.each do |outcome|
        ratings = outcome_proficiency_ratings || outcome.rubric_criterion[:ratings]&.clone

        if opts[:add_defaults] == "true"
          # add mastery level and color defaults to rubric_criterion
          outcome.find_or_set_rating_defaults(ratings, outcome.rubric_criterion[:mastery_points])
        end

        next unless ratings

        # Sort ratings by points descending (highest first)
        sorted_ratings = ratings.sort_by { |r| -r[:points] }

        # Initialize counts and student_ids for each rating
        rating_counts = sorted_ratings.map do |rating|
          {
            description: rating[:description],
            points: rating[:points],
            color: rating[:color] || "#666666",
            count: 0,
            student_ids: []
          }
        end

        # Count students in each rating level and track their IDs
        total_students = 0
        rollups.each do |rollup|
          score_obj = rollup.scores.find { |s| s.outcome.id == outcome.id }
          next unless score_obj&.score

          total_students += 1
          # Find the rating level for this score
          idx = sorted_ratings.find_index { |rating| rating[:points] <= score_obj.score }
          if idx
            rating_counts[idx][:count] += 1
            rating_counts[idx][:student_ids] << rollup.context.id.to_s
          end
        end

        distributions[outcome.id.to_s] = {
          outcome_id: outcome.id.to_s,
          ratings: rating_counts,
          total_students:
        }
      end

      distributions
    end

    # Public: Calculates distribution counts for contributing scores (alignments)
    #
    # outcomes - Array of LearningOutcome objects
    # users - Array of User objects
    # context - Course or Account context
    # results - Array of LearningOutcomeResult objects (both Canvas and OS)
    # options - Hash of options:
    #   :only_assignment_alignments - Boolean, filter to only assignments
    #
    # Returns nested hash: outcome_id => { alignment_id => distribution data }
    def alignment_mastery_distributions(outcomes:, users:, context:, results:, alignments_by_outcome:, options: {})
      outcome_proficiency_ratings = if context&.root_account&.feature_enabled?(:account_level_mastery_scales)
                                      context.resolved_outcome_proficiency.ratings_hash
                                    end

      distributions = {}

      outcomes.each do |outcome|
        alignments = alignments_by_outcome[outcome.id] || []
        next if alignments.empty?

        ratings = outcome_proficiency_ratings || outcome.rubric_criterion[:ratings]
        next unless ratings

        sorted_ratings = ratings.sort_by { |r| -r[:points] }

        # Calculate distribution for each alignment
        alignment_dists = {}
        alignments.each do |alignment|
          # Filter results for this specific alignment
          alignment_results = results.select do |result|
            result.learning_outcome_id == outcome.id && matches_alignment_for_result?(result, alignment)
          end

          # Initialize counts and student_ids
          rating_counts = sorted_ratings.map do |rating|
            {
              description: rating[:description],
              points: rating[:points],
              color: rating[:color] || "#666666",
              count: 0,
              student_ids: []
            }
          end

          # Count scores in each rating level and track student IDs
          total_students = 0
          alignment_results.each do |result|
            next unless result.score

            total_students += 1
            idx = sorted_ratings.find_index { |rating| rating[:points] <= result.score }
            if idx
              rating_counts[idx][:count] += 1
              rating_counts[idx][:student_ids] << result.user_id.to_s
            end
          end

          alignment_dists[alignment.prefixed_id] = {
            alignment_id: alignment.prefixed_id,
            ratings: rating_counts,
            total_students:
          }
        end

        distributions[outcome.id.to_s] = alignment_dists unless alignment_dists.empty?
      end

      distributions
    end

    # Internal: Checks if a result matches an alignment
    def matches_alignment_for_result?(result, alignment)
      # Direct content tag match
      return true if result.alignment&.id == alignment.id

      # Assignment match (handles both Assignment and Quiz)
      if result.associated_asset.is_a?(Assignment)
        return result.associated_asset.id == alignment.content_id if alignment.content_type == "Assignment"
      elsif result.associated_asset.is_a?(Quizzes::Quiz)
        return result.associated_asset.assignment_id == alignment.content_id if alignment.content_type == "Assignment"
      end

      false
    end

    class << self
      include ResultAnalytics
    end
  end
end
