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

module RollupScoreAggregatorHelper
  def aggregate_score
    scores = present_scores
    agg_score = scores.empty? ? nil : (scores.sum.to_f / scores.size).round(2)
    { score: agg_score, results: score_sets.pluck(:result) }
  end

  def median_aggregate_score
    scores = present_scores
    sorted = scores.sort
    median = scores.empty? ? nil : (sorted[(sorted.size - 1) / 2] + sorted[sorted.size / 2]) / 2.0
    { score: median, results: score_sets.pluck(:result) }
  end

  private

  def present_scores
    score_sets.pluck(:score).compact
  end

  def latest_result
    latest_result = @outcome_results.max_by { |result| result_time(result) }
    @submitted_at = latest_result.submitted_at || latest_result.assessed_at
    @title = @submitted_at ? latest_result.title.split(", ")[1] : nil
  end

  def result_time(result)
    (result.submitted_at || result.assessed_at).to_i
  end

  def scaled_score_from_result(result)
    if %w[decaying_average latest average standard_decaying_average weighted_average].include?(@calculation_method)
      result_aggregates = get_aggregates(result)
      alignment_aggregate_score(result_aggregates)
    else
      result_score(result)
    end
  end

  def retrieve_scores(results)
    results.map do |result|
      score = quiz_score?(result) ? scaled_score_from_result(result) : result_score(result)
      { score:, result: }
    end
  end

  def quiz_score?(result)
    result.respond_to?(:artifact_type) && result.artifact_type == "Quizzes::QuizSubmission"
  end

  def sorted_results
    @sorted_results ||= @outcome_results.sort_by { |result| result_time(result) }
  end

  def get_aggregates(result)
    @outcome_results.each_with_object({ total: 0.0, weighted: 0.0 }) do |lor, aggregate|
      next unless is_match?(result, lor) && lor.possible

      aggregate[:total] += lor.possible
      begin
        aggregate[:weighted] += lor.possible * lor.percent
      rescue NoMethodError, TypeError => e
        Canvas::Errors.capture_exception(:missing_percent_or_points_possible, e)
        raise e
      end
    end
  end

  def alignment_aggregate_score(result_aggregates)
    return if result_aggregates[:total] == 0

    possible = (@points_possible > 0) ? @points_possible : @mastery_points
    (result_aggregates[:weighted] / result_aggregates[:total]) * possible
  end

  def is_match?(current_result, compared_result)
    (current_result.association_id == compared_result.association_id) &&
      (current_result.learning_outcome_id == compared_result.learning_outcome_id) &&
      (current_result.association_type == compared_result.association_type)
  end

  def result_score(result)
    return result.score unless result.try(:percent)

    if @points_possible > 0
      result.percent * @points_possible
    else
      result.percent * @mastery_points
    end
  end

  def score_sets
    @score_sets || begin
      case @calculation_method
      when "decaying_average", "standard_decaying_average", "weighted_average"
        @score_sets = retrieve_scores(@aggregate ? @outcome_results : sorted_results)
      when "n_mastery", "highest", "average"
        @score_sets = retrieve_scores(@outcome_results)
      when "latest"
        @score_sets = retrieve_scores(@aggregate ? @outcome_results : [sorted_results.last])
      end
    end
  end
end
