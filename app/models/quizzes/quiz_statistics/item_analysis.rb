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

require 'csv'

class Quizzes::QuizStatistics::ItemAnalysis < Quizzes::QuizStatistics::Report

  def generatable?
    !self.quiz.survey?
  end

  def readable_type
    t('#quizzes.quiz_statistics.types.item_analysis', 'Item Analysis')
  end

  def filename
    "quiz-item-analysis-#{Time.now.to_i}.csv"
  end

  MIN_STATS_FOR_ALPHA = 15

  def generate(legacy=true)
    stats = summary_stats_for_quiz
    stats.map do |item|
      question_item_analysis = {
        question_id: item.question[:id],
        answered_student_count: item.num_respondents,
        top_student_count: item.num_respondents(:top),
        middle_student_count: item.num_respondents(:middle),
        bottom_student_count: item.num_respondents(:bottom),
        correct_student_count: item.num_respondents(:correct),
        incorrect_student_count: item.num_respondents(:incorrect),
        correct_student_ratio: item.ratio_for(:correct),
        incorrect_student_ratio: item.ratio_for(:incorrect),
        correct_top_student_count: item.num_respondents(:top, :correct),
        correct_middle_student_count: item.num_respondents(:middle, :correct),
        correct_bottom_student_count: item.num_respondents(:bottom, :correct),
        variance: item.variance,
        stdev: item.standard_deviation,
        difficulty_index: item.difficulty_index,
        alpha: stats.size > MIN_STATS_FOR_ALPHA ? stats.alpha : nil,
        point_biserials: []
      }

      sorted_answers = item.answers
      item.point_biserials.each_with_index do |point_biserial, i|
        question_item_analysis[:point_biserials] << {
          answer_id: sorted_answers[i],
          point_biserial: point_biserial,
          correct: i == 0,
          distractor: i != 0
        }
      end

      question_item_analysis
    end
  end

  def to_csv
    @csv ||=
      CSV.generate do |csv|
      stats = summary_stats_for_quiz
      headers = [
        I18n.t('csv.question.id', 'Question Id'),
        I18n.t('csv.question.title', 'Question Title'),
        I18n.t('csv.answered.student.count', 'Answered Student Count'),
        I18n.t('csv.top.student.count', 'Top Student Count'),
        I18n.t('csv.middle.student.count', 'Middle Student Count'),
        I18n.t('csv.bottom.student.count', 'Bottom Student Count'),
        I18n.t('csv.quiz.question.count', 'Quiz Question Count'),
        I18n.t('csv.correct.student.count', 'Correct Student Count'),
        I18n.t('csv.wrong.student.count', 'Wrong Student Count'),
        I18n.t('csv.correct.student.ratio', 'Correct Student Ratio'),
        I18n.t('csv.wrong.student.ratio', 'Wrong Student Ratio'),
        I18n.t('csv.correct.top.student.count', 'Correct Top Student Count'),
        I18n.t('csv.correct.middle.student.count', 'Correct Middle Student Count'),
        I18n.t('csv.correct.bottom.student.count', 'Correct Bottom Student Count'),
        I18n.t('csv.variance', 'Variance'),
        I18n.t('csv.standard.deviation', 'Standard Deviation'),
        I18n.t('csv.difficulty.index', 'Difficulty Index'),
        I18n.t('csv.alpha', 'Alpha'),
        I18n.t('csv.point.biserial', 'Point Biserial of Correct')
      ]
      point_biserial_max_count = stats.map { |item| item.point_biserials.size }.max || 0
      (point_biserial_max_count - 1).times do |i|
        headers << I18n.t("csv.point.distractor", 'Point Biserial of Distractor %{num}', :num => i + 2)
      end
      csv << headers
      stats.each_with_index do |item, i|
        update_progress(i, stats.size)
        row = [
          item.question[:id],
          item.question_text,
          item.num_respondents,
          item.num_respondents(:top),
          item.num_respondents(:middle),
          item.num_respondents(:bottom),
          stats.size,
          item.num_respondents(:correct),
          item.num_respondents(:incorrect),
          item.ratio_for(:correct),
          item.ratio_for(:incorrect),
          item.num_respondents(:top, :correct),
          item.num_respondents(:middle, :correct),
          item.num_respondents(:bottom, :correct),
          item.variance,
          item.standard_deviation,
          item.difficulty_index,
          stats.size > MIN_STATS_FOR_ALPHA && stats.alpha ? stats.alpha : "N/A"
        ]
        point_biserial_max_count.times do |n|
          row << item.point_biserials[n]
        end
        csv << row
      end
      end
  end

  private

  def summary_stats_for_quiz
    @summary_stats ||= Quizzes::QuizStatistics::ItemAnalysis::Summary.new(quiz)
  end
end
