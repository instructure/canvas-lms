module RollupScoreAggregatorHelper
  def aggregate_score
    (scores.sum.to_f / scores.size).round(2)
  end

  private
  def latest_result
    latest_result = @outcome_results.max_by{|result| result_time(result) }
    @submitted_at = latest_result.submitted_at || latest_result.assessed_at
    @title = @submitted_at ? latest_result.title.split(", ")[1] : nil
  end

  def result_time(result)
    (result.submitted_at || result.assessed_at).to_i
  end

  def scaled_score_from_result(result)
    if ['decaying_average', 'latest'].include?(@calculation_method)
      result_aggregates = get_aggregates(result)
      alignment_aggregate_score(result_aggregates)
    else
      result_score(result)
    end
  end

  def retrieve_scores(results)
    results.map do |result|
      quiz_score?(result) ? scaled_score_from_result(result) : result_score(result)
    end
  end

  def quiz_score?(result)
    result.respond_to?(:artifact_type) && result.artifact_type == "Quizzes::QuizSubmission"
  end

  def sorted_results
    @sorted_results ||= @outcome_results.sort_by {|result| result_time(result)}
  end

  def get_aggregates(result)
    @outcome_results.reduce({total: 0.0, weighted: 0.0}) do |aggregate, lor|
      if is_match?(result, lor) && lor.possible
        aggregate[:total] += lor.possible
        aggregate[:weighted] += lor.possible * lor.percent
      end
      aggregate
    end
  end

  def alignment_aggregate_score(result_aggregates)
    return if result_aggregates[:total] == 0
    (result_aggregates[:weighted] / result_aggregates[:total]) * @outcome.rubric_criterion[:points_possible]
  end

  def is_match?(current_result, compared_result)
    (current_result.association_id == compared_result.association_id) &&
    (current_result.learning_outcome_id == compared_result.learning_outcome_id) &&
    (current_result.association_type == compared_result.association_type)
  end

  def result_score(result)
    return result.score unless result.try(:percent)
    result.percent * @points_possible
  end

  def scores
    @scores || begin
      case @calculation_method
      when 'decaying_average'
        @scores = retrieve_scores(@aggregate ? @outcome_results : sorted_results)
      when 'n_mastery', 'highest'
        @scores = retrieve_scores(@outcome_results)
      when 'latest'
        @scores = retrieve_scores(@aggregate ? @outcome_results : [sorted_results.last])
      end
    end
  end
end
