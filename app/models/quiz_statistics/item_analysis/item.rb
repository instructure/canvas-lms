class QuizStatistics::ItemAnalysis::Item
  include TextHelper

  def self.from(summary, question)
    return unless allowed_types.include?(question[:question_type])
    new summary, question
  end

  def self.allowed_types
    ["multiple_choice_question", "true_false_question"]
  end

  def initialize(summary, question)
    @summary = summary
    @question = question
    # put the correct answer first
    @answers = question[:answers].
                each_with_index.
                sort_by{ |answer, i| [-answer[:weight], i] }.
                map{ |answer, i| answer[:id] }
    @respondent_ids = []
    @respondent_map = Hash.new{ |hash, key| hash[key] = [] }
    @scores = []
  end

  def add_response(answer, respondent_id)
    return unless answer[:answer_id] # blanks don't count for item stats
    answer_id = answer[:answer_id]
    @scores << (answer_id == @answers.first ? question[:points_possible] : 0)
    @respondent_ids << respondent_id
    @respondent_map[answer_id] << respondent_id
  end

  attr_reader :question

  def question_text
    strip_tags @question[:question_text]
  end

  # get number of respondents that match the specified filter(s). if no
  # filters are given, just return the respondent count.
  # filters may be:
  #   :correct
  #   :incorrect
  #   <summary bucket symbol> (e.g. :top)
  #   <answer id>
  #
  # e.g. num_respondents(:correct, :top) => # of students in the top 27%
  #                                         # who got it right
  def num_respondents(*filters)
    respondents = all_respondents
    filters.each do |filter|
      respondents &= respondents_for(filter)
    end
    respondents.size
  end

  # population variance, not sample variance, since we have all datapoints
  def variance
    @variance ||= SimpleStats.variance(@scores)
  end

  # population sd, not sample sd, since we have all datapoints
  def standard_deviation
    @sd ||= Math.sqrt(variance)
  end

  def difficulty_index
    ratio_for(:correct)
  end

  def point_biserials
    @answers.map { |answer|
      point_biserial_for(answer)
    }
  end

  def ratio_for(answer)
    respondents_for(answer).size.to_f / all_respondents.size
  end

  def <=>(other)
    sort_key <=> other.sort_key
  end

  def sort_key
    [question[:position] || 10000, question_text, question[:id], -all_respondents.size]
  end

  private

  def correct_answer
    @answers.first
  end

  def all_respondents
    @respondent_ids
  end

  def respondents_for(filter)
    @respondents_for ||= {}
    @respondents_for[filter] = if filter == :correct
      respondents_for(correct_answer)
    elsif filter == :incorrect
      all_respondents - respondents_for(correct_answer)
    elsif @summary.buckets[filter]
      all_respondents & @summary.buckets[filter]
    else # filter is an answer
      @respondent_map[filter] || []
    end
  end

  def point_biserial_for(answer)
    @point_biserials ||= {}
    @point_biserials[answer] ||= begin
      mean, mean_other = mean_score_split(answer)
      if mean
        ratio = ratio_for(answer)
        sd = @summary.standard_deviation(all_respondents)
        (mean - mean_other) / sd * Math.sqrt(ratio * (1 - ratio))
      end
    end
  end

  # calculate:
  # 1. the mean score of those who chose the given answer
  # 2. the mean score of those who chose any other answer
  def mean_score_split(answer)
    these_respondents = respondents_for(answer)
    other_respondents = all_respondents - these_respondents
    [
      @summary.mean_score_for(these_respondents),
      @summary.mean_score_for(other_respondents)
    ]
  end
end

