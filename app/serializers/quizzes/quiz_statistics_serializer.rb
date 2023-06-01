# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

module Quizzes
  class QuizStatisticsSerializer < Canvas::APISerializer
    SubmissionStatisticsExtractor = /^submission_(.+)/

    # Utilizes both Student and Item analysis to generate a compound document of
    # quiz statistics.
    #
    # This is what you should pass to this serializer!!!
    Input = Struct.new(:quiz, :options, :student_analysis, :item_analysis) do
      include ActiveModel::SerializerSupport
    end

    root :quiz_statistics

    # the id is really only included in JSON-API and only because the spec
    # requires it, this is because the output of this serializer is a mix of
    # two entities, an id doesn't make much sense, but we'll use the id of the
    # StudentAnalysis when needed
    attributes :id,
               :url,
               :html_url,
               # whether any of the participants has taken the quiz more than one time
               :multiple_attempts_exist,
               # the time of the generation of the analysis (the earliest one)
               :generated_at,
               # whether the statistics were based on earlier and current quiz submissions
               #
               # PS: this is always true for item analysis
               :includes_all_versions,
               # whether statistics report includes sis ids
               # always false for item analysis
               :includes_sis_ids,
               :points_possible,
               :anonymous_survey,
               :speed_grader_url,
               :quiz_submissions_zip_url,
               # an aggregate of question stats from both student and item analysis
               :question_statistics,
               # submission-related statistics (extracted from student analysis):
               #
               #   - correct_count_average
               #   - incorrect_count_average
               #   - duration_average
               #   - score_average
               #   - score_high
               #   - score_low
               #   - score_stdev
               :submission_statistics

    def_delegators :@controller,
                   :course_quiz_statistics_url,
                   :api_v1_course_quiz_url,
                   :api_v1_course_quiz_statistics_url,
                   :speed_grader_course_gradebook_url,
                   :course_quiz_quiz_submissions_url

    has_one :quiz, embed: :ids

    def id
      object[:student_analysis].id
    end

    def url
      api_v1_course_quiz_statistics_url(object.quiz.context, object.quiz)
    end

    def html_url
      course_quiz_statistics_url(object.quiz.context, object.quiz)
    end

    def quiz_url
      api_v1_course_quiz_url(object.quiz.context, object.quiz)
    end

    def question_statistics
      # entries in the :questions set are pairs of a static string and actual
      # question data, e.g:
      #
      # [['question', { id: 1, ... }], ['question', { id:2, ... }]]
      question_statistics = student_analysis_report[:questions].collect(&:last)

      # we're going to merge the item analysis for applicable questions into the
      # generic question statistics from the student analysis
      question_statistics.each do |question|
        question_id = question[:id] = question[:id].to_s
        question_item = item_analysis_report.detect do |item|
          item[:question_id].to_s == question_id
        end

        if question_item.present?
          question.merge! question_item.except(:question_id)
        end
      end

      question_statistics
    end

    def submission_statistics
      {}.tap do |out|
        student_analysis_report.each_pair do |key, statistic|
          out[$1] = statistic if key =~ SubmissionStatisticsExtractor
        end

        out.delete("user_ids")
        out.delete("logged_out_users")

        out["unique_count"] = student_analysis_report[:unique_submission_count]
      end
    end

    def generated_at
      [object[:student_analysis], object[:item_analysis]].map(&:created_at).min
    end

    def multiple_attempts_exist
      student_analysis_report[:multiple_attempts_exist]
    end

    def includes_all_versions
      object[:student_analysis].includes_all_versions
    end

    def includes_sis_ids
      object[:student_analysis].includes_sis_ids
    end

    delegate points_possible: :quiz

    def anonymous_survey
      quiz.anonymous_survey?
    end

    def speed_grader_url
      if show_speed_grader?
        speed_grader_course_gradebook_url(quiz.context, {
                                            assignment_id: quiz.assignment.id
                                          })
      end
    end

    def quiz_submissions_zip_url
      course_quiz_quiz_submissions_url(quiz.context, quiz.id, zip: 1)
    end

    private

    def show_speed_grader?
      quiz.assignment.present? && quiz.published? && quiz.assignment.can_view_speed_grader?(current_user)
    end

    def student_analysis_report
      @student_analysis_report ||= object[:student_analysis].report.generate(false, object.options)
    end

    def item_analysis_report
      @item_analysis_report ||= object[:item_analysis].report.generate(false, object.options)
    end

    def quiz
      object.quiz
    end
  end
end
