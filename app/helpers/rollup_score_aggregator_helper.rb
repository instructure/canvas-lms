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
    result.percent * @outcome.rubric_criterion[:points_possible]
  end

  def scaled_scores
    @scaled_scores ||= @outcome_results.map {|result| scaled_score_from_result(result)}
  end

  def raw_scores
    @raw_scores ||= @outcome_results.map(&:score)
  end

  def sorted_results
    @sorted_results ||= @outcome_results.sort_by {|result| result_time(result)}
  end

  def scores
    @scores || begin
      @quiz_score ||= @outcome_results.first.respond_to?(:artifact_type) ? @outcome_results.first.artifact_type == "Quizzes::QuizSubmission" : false
      case @calculation_method
      when 'decaying_average'
        @scores = @quiz_score ? sorted_results.map {|r| scaled_score_from_result(r)} : sorted_results.map(&:score)
      when 'n_mastery'
        @scores = @quiz_score ? scaled_scores : raw_scores
      when 'latest'
        chosen_result = sorted_results.last
        @scores = @quiz_score ? [scaled_score_from_result(chosen_result)] : [chosen_result.score]
      when 'highest'
        @scores = @quiz_score ? scaled_scores : raw_scores
      end
    end
  end
end
