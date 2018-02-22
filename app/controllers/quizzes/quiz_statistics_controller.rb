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
#

# @API Quiz Statistics
#
# API for accessing quiz submission statistics. The statistics provided by this
# interface are an aggregate of what is known as Student and Item Analysis for a
# quiz.
#
# These statistics are extracted (and composed) from _graded_ (manually or, when
# viable, automatically) submissions for a quiz and provide an insight into how
# the participant students had responded to each question, as well as insights
# into the reception of each question answer individually.
#
# Some of these statistics are exclusive to Multiple Choice and True/False types
# of questions, others to other question types. See
# {Appendix: Question Specific Statistics} for a reference of these statistics.
#
# @model QuizStatistics
#     {
#       "id": "QuizStatistics",
#       "required": [ "id", "quiz_id" ],
#       "properties": {
#         "id": {
#           "description": "The ID of the quiz statistics report.",
#           "example": 1,
#           "type": "integer",
#           "format": "int64"
#         },
#         "quiz_id": {
#           "description": "The ID of the Quiz the statistics report is for. \nNOTE: AVAILABLE ONLY IN NON-JSON-API REQUESTS.",
#           "example": 2,
#           "type": "integer",
#           "format": "int64"
#         },
#         "multiple_attempts_exist": {
#           "description": "Whether there are any students that have made mutliple submissions for this quiz.",
#           "example": true,
#           "type": "boolean"
#         },
#         "includes_all_versions": {
#           "description": "In the presence of multiple attempts, this field describes whether the statistics describe all the submission attempts and not only the latest ones.",
#           "example": true,
#           "type": "boolean"
#         },
#         "generated_at": {
#           "description": "The time at which the statistics were generated, which is usually after the occurrence of a quiz event, like a student submitting it.",
#           "example": "2013-01-23T23:59:00-07:00",
#           "type": "datetime"
#         },
#         "url": {
#           "description": "The API HTTP/HTTPS URL to this quiz statistics.",
#           "example": "http://canvas.example.edu/api/v1/courses/1/quizzes/2/statistics",
#           "type": "string"
#         },
#         "html_url": {
#           "description": "The HTTP/HTTPS URL to the page where the statistics can be seen visually.",
#           "example": "http://canvas.example.edu/courses/1/quizzes/2/statistics",
#           "type": "string"
#         },
#         "question_statistics": {
#           "$ref": "QuizStatisticsQuestionStatistics",
#           "description": "Question-specific statistics for each question and its answers."
#         },
#         "submission_statistics": {
#           "$ref": "QuizStatisticsSubmissionStatistics",
#           "description": "Question-specific statistics for each question and its answers."
#         },
#         "links": {
#           "$ref": "QuizStatisticsLinks",
#           "description": "JSON-API construct that contains links to media related to this quiz statistics object. \nNOTE: AVAILABLE ONLY IN JSON-API REQUESTS."
#         }
#       }
#     }
#
# @model QuizStatisticsLinks
#     {
#       "id": "QuizStatisticsLinks",
#       "description": "Links to media related to QuizStatistics.",
#       "properties": {
#         "quiz": {
#           "description": "HTTP/HTTPS API URL to the quiz this statistics describe.",
#           "type": "string",
#           "example": "http://canvas.example.edu/api/v1/courses/1/quizzes/2"
#         }
#       }
#     }
#
# @model QuizStatisticsQuestionStatistics
#     {
#       "id": "QuizStatisticsQuestionStatistics",
#       "description": "Statistics for submissions made to a specific quiz question.",
#       "properties": {
#         "responses": {
#           "description": "Number of students who have provided an answer to this question. Blank or empty responses are not counted.",
#           "example": 3,
#           "type": "integer",
#           "format": "int64"
#         },
#         "answers": {
#           "$ref": "QuizStatisticsAnswerStatistics",
#           "description": "Statistics related to each individual pre-defined answer."
#         }
#       }
#     }
#
# @model QuizStatisticsAnswerStatistics
#     {
#       "id": "QuizStatisticsAnswerStatistics",
#       "description": "Statistics for a specific pre-defined answer in a Multiple-Choice or True/False quiz question.",
#       "properties": {
#         "id": {
#           "description": "ID of the answer.",
#           "example": 3866,
#           "type": "integer",
#           "format": "int64"
#         },
#         "text": {
#           "description": "The text attached to the answer.",
#           "example": "Blue.",
#           "type": "string"
#         },
#         "weight": {
#           "description": "An integer to determine correctness of the answer. Incorrect answers should be 0, correct answers should be non-negative.",
#           "example": 100,
#           "type": "integer",
#           "format": "int64"
#         },
#         "responses": {
#           "description": "Number of students who have chosen this answer.",
#           "example": 2,
#           "type": "integer",
#           "format": "int64"
#         }
#       }
#     }
#
# @model QuizStatisticsAnswerPointBiserial
#     {
#       "id": "QuizStatisticsAnswerPointBiserial",
#       "description": "A point-biserial construct for a single pre-defined answer in a Multiple-Choice or True/False question.",
#       "properties": {
#         "answer_id": {
#           "description": "ID of the answer the point biserial is for.",
#           "example": 3866,
#           "type": "integer",
#           "format": "int64"
#         },
#         "point_biserial": {
#           "description": "The point biserial value for this answer. Value ranges between -1 and 1.",
#           "example": -0.802955068546966,
#           "type": "number"
#         },
#         "correct": {
#           "description": "Convenience attribute that denotes whether this is the correct answer as opposed to being a distractor. This is mutually exclusive with the `distractor` value",
#           "type": "boolean",
#           "example": true
#         },
#         "distractor": {
#           "description": "Convenience attribute that denotes whether this is a distractor answer and not the correct one. This is mutually exclusive with the `correct` value",
#           "type": "boolean",
#           "example": false
#         }
#       }
#     }
#
# @model QuizStatisticsSubmissionStatistics
#     {
#       "id": "QuizStatisticsSubmissionStatistics",
#       "description": "Generic statistics for all submissions for a quiz.",
#       "properties": {
#         "unique_count": {
#           "description": "The number of students who have taken the quiz.",
#           "example": 3,
#           "type": "integer",
#           "format": "int64"
#         },
#         "score_average": {
#           "description": "The mean of the student submission scores.",
#           "example": 4.33333333333333,
#           "type": "number"
#         },
#         "score_high": {
#           "description": "The highest submission score.",
#           "example": 6,
#           "type": "number"
#         },
#         "score_low": {
#           "description": "The lowest submission score.",
#           "example": 3,
#           "type": "number"
#         },
#         "score_stdev": {
#           "description": "Standard deviation of the submission scores.",
#           "example": 1.24721912892465,
#           "type": "number"
#         },
#         "scores": {
#           "description": "A percentile distribution of the student scores, each key is the percentile (ranges between 0 and 100%) while the value is the number of students who received that score.",
#           "example": { "50": 1, "34": 5, "100": 1 },
#           "type": "object"
#         },
#         "correct_count_average": {
#           "description": "The mean of the number of questions answered correctly by each student.",
#           "example": 3.66666666666667,
#           "type": "number"
#         },
#         "incorrect_count_average": {
#           "description": "The mean of the number of questions answered incorrectly by each student.",
#           "example": 5,
#           "type": "number"
#         },
#         "duration_average": {
#           "description": "The average time spent by students while taking the quiz.",
#           "example": 42.333333333,
#           "type": "number"
#         }
#       }
#     }
#
class Quizzes::QuizStatisticsController < ApplicationController
  include ::Filters::Quizzes

  before_action :require_user, :require_context, :require_quiz, :prepare_service

  # @API Fetching the latest quiz statistics
  #
  # This endpoint provides statistics for all quiz versions, or for a specific
  # quiz version, in which case the output is guaranteed to represent the
  # _latest_ and most current version of the quiz.
  #
  # @argument all_versions [Boolean]
  #   Whether the statistics report should include all submissions attempts.
  #
  # <b>200 OK</b> response code is returned if the request was successful.
  #
  # @example_response
  #  {
  #    "quiz_statistics": [ QuizStatistics ]
  #  }
  def index
    if authorized_action(@quiz, @current_user, :read_statistics)
      scope = @quiz.quiz_submissions.not_settings_only.completed
      updated = scope.order('updated_at DESC').limit(1).pluck(:updated_at).first
      cache_key = [
        'quiz_statistics',
        @quiz.id,
        @quiz.updated_at,
        updated,
        params[:all_versions],
        params[:section_ids]
      ].cache_key

      if Quizzes::QuizStatistics.large_quiz?(@quiz)
        head :no_content  #operation not available for large quizzes
      else
        json = Rails.cache.fetch(cache_key) do
          all_versions = value_to_boolean(params[:all_versions])
          statistics = @service.generate_aggregate_statistics(all_versions, {section_ids: params[:section_ids]})
          serialize(statistics)
        end

        render json: json
      end
    end
  end

  private

  def prepare_service
    @service = Quizzes::QuizStatisticsService.new(@quiz)
  end

  def serialize(statistics)
    Canvas::APIArraySerializer.new([ statistics ], {
      controller: self,
      each_serializer: Quizzes::QuizStatisticsSerializer,
      root: :quiz_statistics,
      include_root: false
    }).as_json
  end

  # @!appendix Question Specific Statistics
  #
  #   {include:file:doc/examples/question_specific_statistics.md}
end
