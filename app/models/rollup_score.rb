# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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
class RollupScore
  include RollupScoreAggregatorHelper

  PRECISION = 2

  attr_reader :outcome_results, :outcome, :score, :count, :title, :submitted_at, :hide_points

  def initialize(outcome_results:, opts: {})
    @outcome_results = outcome_results
    @aggregate = opts[:aggregate_score]
    @median = opts[:aggregate_stat] == "median"
    @outcome = @outcome_results.first.learning_outcome
    @count = @outcome_results.size
    if opts[:points_possible].present?
      @points_possible = opts[:points_possible]
      @mastery_points = opts[:mastery_points]
    else
      @points_possible = @outcome.rubric_criterion[:points_possible]
      @mastery_points = @outcome.rubric_criterion[:mastery_points]
    end

    if opts[:calculation_method].present?
      @calculation_method = opts[:calculation_method]
      @calculation_int = opts[:calculation_int]
    else
      @calculation_method = @outcome.calculation_method || "highest"
      @calculation_int = @outcome.calculation_int
    end

    score_set = if @aggregate
                  @median ? median_aggregate_score : aggregate_score
                else
                  calculate_results
                end
    @score = score_set[:score] if score_set
    @hide_points = score_set[:results].all?(&:hide_points) if score_set
    latest_result unless @aggregate
  end

  def new_decaying_average_calculation_ff_enabled?
    return @outcome.context.root_account.feature_enabled?(:outcomes_new_decaying_average_calculation) if @outcome.context

    LoadAccount.default_domain_root_account.feature_enabled?(:outcomes_new_decaying_average_calculation)
  end

  # TODO: This code should be removed once the FF is retire and DB is migrated
  def adjust_calculation_method
    if new_decaying_average_calculation_ff_enabled?
      case @calculation_method
      when "standard_decaying_average"
        "decaying_average"
      when "decaying_average", "weighted_average"
        "weighted_average"
      else
        @calculation_method
      end
    else
      case @calculation_method
      when "standard_decaying_average", "decaying_average", "weighted_average"
        "weighted_average"
      else
        @calculation_method
      end
    end
  end

  # TODO: do send(@calculation_method) instead of the case to streamline this more
  def calculate_results
    # decaying average is default for new outcomes
    # TODO: This line should be removed once the FF is retire and DB is migrated
    # and use @calculation_method instead of method
    method = adjust_calculation_method

    case method
    when "decaying_average"
      return nil if @outcome_results.empty?

      standard_decaying_average
    when "weighted_average"
      return nil if @outcome_results.empty?

      decaying_average_set
    when "n_mastery"
      return nil if @outcome_results.length < @calculation_int

      n_mastery_set
    when "latest"
      latest_set = score_sets.first
      { score: latest_set[:score].round(PRECISION), results: [latest_set[:result]] }
    when "highest"
      highest_set = score_sets.max_by { |set| set[:score] }
      { score: highest_set[:score].round(PRECISION), results: [highest_set[:result]] }
    when "average"
      return nil if @outcome_results.empty?

      average_set
    end
  end

  def n_mastery_set
    return unless @outcome.rubric_criterion

    # mastery_points represents the cutoff score for which results
    # will be considered towards mastery
    tmp_score_sets = score_sets.compact.delete_if { |set| set[:score] < @mastery_points }
    return nil if tmp_score_sets.length < @calculation_int

    tmp_scores = tmp_score_sets.pluck(:score)
    n_mastery_score = (tmp_scores.sum.to_f / tmp_scores.size).round(PRECISION)
    { score: n_mastery_score, results: tmp_score_sets.pluck(:result) }
  end

  def decaying_average_set
    # The term "decaying average" can mean different things depending on the user.
    # There are multiple, reasonable, accurate interpretations.  We have chosen
    # to go with one that is more mathematically a "weighted average", but is
    # typically what is meant when a "decaying average" is wanted.  A true
    # decaying average may be added in the future.

    # default grading method with weight of 65 if none selected.
    weight = @calculation_int || 65
    tmp_score_sets = score_sets
    latest = tmp_score_sets.pop

    if tmp_score_sets.empty?
      return { score: latest[:score].round(PRECISION), results: [latest[:result]] }
    end

    tmp_scores = tmp_score_sets.pluck(:score)
    latest_weighted = latest[:score] * (0.01 * weight)
    older_avg_weighted = (tmp_scores.sum / tmp_scores.length) * (0.01 * (100 - weight))
    decaying_avg_score = (latest_weighted + older_avg_weighted).round(PRECISION)
    { score: decaying_avg_score, results: tmp_score_sets.pluck(:result).push(latest[:result]) }
  end

  def standard_decaying_average
    # default decay_rate is 65 if none selected.
    decay_rate = @calculation_int || 65
    remaining_weight = 100 - decay_rate
    decay_avg = nil

    tmp_scores = score_sets.pluck(:score)
    results = score_sets.pluck(:result)

    # return if single assignment score
    if tmp_scores.size == 1
      decay_avg = tmp_scores[0].round(PRECISION)
      return { score: decay_avg, results: }
    end

    tmp_scores.each_cons(2) do |score|
      decay_avg = if decay_avg.nil?
                    (score[0] * (0.01 * remaining_weight)) + (score[1] * (0.01 * decay_rate))
                  else
                    (decay_avg * (0.01 * remaining_weight)) + (score[1] * (0.01 * decay_rate))
                  end
    end

    { score: decay_avg.round(PRECISION), results: }
  end

  def average_set
    tmp_scores = score_sets.pluck(:score)
    average_score = (tmp_scores.sum.to_f / tmp_scores.size).round(PRECISION)
    { score: average_score, results: score_sets.pluck(:result) }
  end
end
