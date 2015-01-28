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
  attr_reader :outcome_results, :outcome, :score, :count, :title, :submitted_at
  def initialize(outcome_results, opts={})
    @outcome_results = outcome_results
    @outcome = @outcome_results.first.learning_outcome
    @count = @outcome_results.size
    @calculation_method = @outcome.calculation_method || "highest"
    @calculation_int = @outcome.calculation_int
    @score = opts[:aggregate_score] ? get_aggregate_score : calculate_results
    get_latest_result unless opts[:aggregate_score]
  end

#todo - do send(@calculation_method) instead of the case to streamline this more
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
        @outcome_results.max_by{|result| result.submitted_at.to_i}.score
      when 'highest'
        @outcome_results.max_by{|result| result.score}.score
    end
  end

  def n_mastery
    scores = @outcome_results.map(&:score).sort.last(@calculation_int)
    (scores.sum.to_f / scores.size).round(2)
  end

  def decaying_average
    #default grading method with weight of 65 if none selected.
    weight = @calculation_int || 65
    scores = @outcome_results.sort_by{|result| result.submitted_at.to_i}.map(&:score)
    latestWeighted = scores.pop * (0.01 * weight)
    olderAvgWeighted = (scores.sum / scores.length) * (0.01 * (100 - weight)).round(2)
    latestWeighted + olderAvgWeighted
  end

  def get_latest_result
    latest_result = @outcome_results.max_by{|result| result.submitted_at.to_i}
    @submitted_at = latest_result.submitted_at
    @title = @submitted_at ? latest_result.title.split(", ")[1] : nil
  end

  def get_aggregate_score
    scores = @outcome_results.map(&:score)
    (scores.sum.to_f / scores.size).round(2)
  end
end