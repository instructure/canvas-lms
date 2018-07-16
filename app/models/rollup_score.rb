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
  def initialize(outcome_results, opts={})
    @outcome_results = outcome_results
    @aggregate = opts[:aggregate_score]
    @median = opts[:aggregate_stat] == 'median'
    @outcome = @outcome_results.first.learning_outcome
    @count = @outcome_results.size
    @points_possible = @outcome.rubric_criterion[:points_possible]
    @mastery_points = @outcome.rubric_criterion[:mastery_points]
    @calculation_method = @outcome.calculation_method || "highest"
    @calculation_int = @outcome.calculation_int
    score_set = if @aggregate
                  @median ? median_aggregate_score : aggregate_score
                else
                  calculate_results
    end
    @score = score_set[:score] if score_set
    @hide_points = score_set[:results].all?(&:hide_points) if score_set
    latest_result unless @aggregate
  end

  # TODO: do send(@calculation_method) instead of the case to streamline this more
  def calculate_results
    # decaying average is default for new outcomes
    case @calculation_method
    when 'decaying_average'
      return nil if @outcome_results.empty?
      decaying_average_set
    when 'n_mastery'
      return nil if @outcome_results.length < @calculation_int
      n_mastery_set
    when 'latest'
      latest_set = score_sets.first
      {score: latest_set[:score].round(PRECISION), results: [latest_set[:result]]}
    when 'highest'
      highest_set = score_sets.max_by{|set| set[:score]}
      {score: highest_set[:score].round(PRECISION), results: [highest_set[:result]]}
    end
  end

  def n_mastery_set
    return unless @outcome.rubric_criterion
    # mastery_points represents the cutoff score for which results
    # will be considered towards mastery
    tmp_score_sets = score_sets.compact.delete_if{|set| set[:score] < @mastery_points}
    return nil if tmp_score_sets.length < @calculation_int

    tmp_scores = tmp_score_sets.pluck(:score)
    n_mastery_score = (tmp_scores.sum.to_f / tmp_scores.size).round(PRECISION)
    {score: n_mastery_score, results: tmp_score_sets.pluck(:result)}
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
    {score: decaying_avg_score, results: tmp_score_sets.pluck(:result).push(latest[:result])}
  end

end
