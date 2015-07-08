#
# Copyright (C) 2013 Instructure, Inc.
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

class Quizzes::QuizStatistics::ItemAnalysis::Summary
  include Enumerable
  extend Forwardable

  def_delegators :sorted_items, :size, :length, :each

  def initialize(quiz, options = {})
    @quiz = quiz
    @items = {}
    @attempts = quiz.quiz_submissions.for_students(quiz).map { |qs| qs.submitted_attempts.first }.compact
    @options = options
    @options[:buckets] ||= [
      [:bottom, 0.27],
      [:middle, 0.73],
      [:top, 1]
    ]

    aggregate_data
  end

  def aggregate_data
    @attempts.each do |attempt|
      add_respondent attempt.user_id, attempt.score
      attempt.quiz_data.each_with_index do |question, i|
        add_response question, attempt.submission_data[i], attempt.user_id
      end
    end
  end

  def add_response(question, answer, respondent_id)
    id = question[:id]
    @items[id] ||= Quizzes::QuizStatistics::ItemAnalysis::Item.from(self, question) || return
    @items[id].add_response(answer, respondent_id)
  end

  def add_respondent(respondent_id, score)
    @respondent_scores ||= {}
    @respondent_scores[respondent_id] = score
  end

  # group the student ids into buckets according to score (e.g. bottom
  # 27%, middle 46%, top 27%)
  def buckets
    @buckets ||= begin
                   buckets = @options[:buckets]
                   ranked_respondent_ids = @respondent_scores.sort_by(&:last).map(&:first)
                   Hash[buckets.each_with_index.map { |(name, cutoff), i|
                     floor = i > 0 ? (buckets[i - 1][1] * ranked_respondent_ids.length).round : 0
                     ceiling = (cutoff * ranked_respondent_ids.length).round
                     [name, ranked_respondent_ids[floor...ceiling]]
                   }]
                 end
  end

  def mean_score_for(respondent_ids)
    return nil if respondent_ids.empty?
    @respondent_scores.slice(*respondent_ids).values.sum * 1.0 / respondent_ids.size
  end

  def sorted_items
    @sorted_items ||= @items.values.sort
  end

  # population variance, not sample variance, since we have all datapoints
  def variance(respondent_ids = :all)
    @variance ||= {}
    @variance[respondent_ids] ||= begin
                                    scores = (respondent_ids == :all ? @respondent_scores : @respondent_scores.slice(*respondent_ids)).values
                                    SimpleStats.variance(scores)
                                  end
  end

  # population sd, not sample sd, since we have all datapoints
  def standard_deviation(respondent_ids = :all)
    @sd ||= {}
    @sd[respondent_ids] ||= Math.sqrt(variance(respondent_ids))
  end

  def alpha
    @alpha ||= begin
                 if variance != 0
                   items = @items.values
                   variance_sum = items.map(&:variance).sum
                   items.size / (items.size - 1.0) * (1 - variance_sum / variance)
                 else
                   nil
                 end
               end
  end
end
