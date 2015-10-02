#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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

  attr_reader :outcome_results, :outcome, :score, :count, :title, :submitted_at
  def initialize(outcome_results, opts={})
    @outcome_results = outcome_results
    @outcome = @outcome_results.first.learning_outcome
    @count = @outcome_results.size
    @calculation_method = @outcome.calculation_method || "highest"
    @calculation_int = @outcome.calculation_int
    @score = opts[:aggregate_score] ? aggregate_score : calculate_results
    latest_result unless opts[:aggregate_score]
  end

  # TODO - do send(@calculation_method) instead of the case to streamline this more
  def calculate_results
    # decaying average is default for new outcomes
    case @calculation_method
    when 'decaying_average'
      return nil if @outcome_results.length < 2
      decaying_average
    when 'n_mastery'
      return nil if @outcome_results.length < @calculation_int
      n_mastery
    when 'latest'
      scores.first
    when 'highest'
      scores.max
    end
  end

  def n_mastery
    n_scores = scores.sort.last(@calculation_int)
    (n_scores.sum.to_f / n_scores.size).round(2)
  end

  def decaying_average
    # The term "decaying average" can mean different things depending on the user.
    # There are multiple, reasonable, accurate interpretations.  We have chosen
    # to go with one that is more mathematically a "weighted average", but is
    # typically what is meant when a "decaying average" is wanted.  A true
    # decaying average may be added in the future.

    #default grading method with weight of 65 if none selected.
    weight = @calculation_int || 65
    tmp_scores = scores
    latest_weighted = tmp_scores.pop * (0.01 * weight)
    older_avg_weighted = (tmp_scores.sum / tmp_scores.length) * (0.01 * (100 - weight))
    (latest_weighted + older_avg_weighted).round(2)
  end


end
