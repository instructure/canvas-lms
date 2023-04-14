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

class Quizzes::QuizStatistics::ItemAnalysis::Item
  include HtmlTextHelper

  # set of IDs of sorted answers, the first would be the correct answer
  attr_reader :answers

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
    @answers = question[:answers]
               .each_with_index
               .sort_by { |answer, i| [-answer[:weight], i] }
               .map { |answer, _i| answer[:id] }
    @respondent_ids = []
    @respondent_map = Hash.new { |hash, key| hash[key] = [] }
    @scores = []
  end

  def add_response(answer, respondent_id)
    return unless answer[:answer_id] # blanks don't count for item stats

    answer_id = answer[:answer_id]
    @scores << ((answer_id == @answers.first) ? question[:points_possible] : 0)
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
    @answers.map do |answer|
      point_biserial_for(answer)
    end
  end

  def ratio_for(answer)
    ratio = respondents_for(answer).size.to_f / all_respondents.size
    ratio.nan? ? 0 : ratio
  end

  def <=>(other)
    sort_key <=> other.sort_key
  end

  def sort_key
    [question[:position] || 10_000, question_text, question[:id], -all_respondents.size]
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
      if mean && mean_other
        ratio = ratio_for(answer)
        sd = @summary.standard_deviation(all_respondents)
        resp = (mean - mean_other) / sd * Math.sqrt(ratio * (1 - ratio))
        resp.nan? ? nil : resp
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
