# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

# @API Assessment Question Banks
#
# @model AssessmentQuestionBank
#   {
#     "id": "AssessmentQuestionBank",
#     "required": ["id", "context_id", "context_type", "title"],
#     "properties": {
#       "id": {
#         "description": "The ID of the assessment question bank.",
#         "example": 1,
#         "type": "integer",
#         "format": "int64"
#       },
#       "context_id": {
#         "description": "The ID of the context (course or account) the question bank belongs to.",
#         "example": 2,
#         "type": "integer",
#         "format": "int64"
#       },
#       "context_type": {
#         "description": "The type of context (Course or Account).",
#         "example": "Course",
#         "type": "string"
#       },
#       "title": {
#         "description": "The title of the question bank.",
#         "example": "Chapter 1 Questions",
#         "type": "string"
#       },
#       "workflow_state": {
#         "description": "The workflow state of the question bank.",
#         "example": "active",
#         "type": "string"
#       },
#       "assessment_question_count": {
#         "description": "The number of questions in the bank.",
#         "example": 10,
#         "type": "integer",
#         "format": "int64"
#       },
#       "context_code": {
#         "description": "The combined context type and ID.",
#         "example": "course_2",
#         "type": "string"
#       },
#       "created_at": {
#         "description": "The date and time the question bank was created.",
#         "example": "2013-01-01T00:00:00Z",
#         "type": "string",
#         "format": "date-time"
#       },
#       "updated_at": {
#         "description": "The date and time the question bank was last updated.",
#         "example": "2013-01-01T00:00:00Z",
#         "type": "string",
#         "format": "date-time"
#       }
#     }
#   }
#
# @model AssessmentQuestion
#   {
#     "id": "AssessmentQuestion",
#     "required": ["id"],
#     "properties": {
#       "id": {
#         "description": "The ID of the assessment question.",
#         "example": 1,
#         "type": "integer",
#         "format": "int64"
#       },
#       "position": {
#         "description": "The order of the question.",
#         "example": 1,
#         "type": "integer",
#         "format": "int64"
#       },
#       "assessment_question_bank_id": {
#         "description": "The ID of the question bank this question belongs to.",
#         "example": 3,
#         "type": "integer",
#         "format": "int64"
#       },
#       "created_at": {
#         "description": "The date and time when the assessment question was created.",
#         "example": "2013-01-23T23:59:00-07:00",
#         "type": "string",
#         "format": "date-time"
#       },
#       "question_name": {
#         "description": "The name of the question.",
#         "example": "Prime Number Identification",
#         "type": "string"
#        },
#       "question_type": {
#         "description": "The type of the question.",
#         "example": "multiple_choice_question",
#         "type": "string"
#       },
#       "question_text": {
#         "description": "The text of the question.",
#         "example": "Which of the following is NOT a prime number?",
#         "type": "string"
#       },
#       "points_possible": {
#         "description": "The maximum amount of points possible received for getting this question correct.",
#         "example": 5,
#         "type": "number"
#       },
#       "correct_comments": {
#         "description": "The comments to display if the student answers the question correctly.",
#         "example": "That's correct!",
#         "type": "string"
#       },
#       "incorrect_comments": {
#         "description": "The comments to display if the student answers incorrectly.",
#         "example": "Unfortunately, that IS a prime number.",
#         "type": "string"
#       },
#       "neutral_comments": {
#         "description": "The comments to display regardless of how the student answered.",
#         "example": "Goldbach's conjecture proposes that every even integer greater than 2 can be expressed as the sum of two prime numbers.",
#         "type": "string"
#       },
#       "correct_comments_html": {
#         "description": "The HTML version of the comments to display if the student answers the question correctly.",
#         "example": "<p>That's correct!</p>",
#         "type": "string"
#       },
#       "incorrect_comments_html": {
#         "description": "The HTML version of the comments to display if the student answers incorrectly.",
#         "example": "<p>Unfortunately, that IS a prime number.</p>",
#         "type": "string"
#       },
#       "neutral_comments_html": {
#         "description": "The HTML version of the comments to display regardless of how the student answered.",
#         "example": "<p>Goldbach's conjecture proposes that every even integer greater than 2 can be expressed as the sum of two prime numbers.</p>",
#         "type": "string"
#       },
#       "answers": {
#         "description": "An array of available answers. Each answer contains id, text, html, comments, comments_html, and weight properties.",
#         "type": "array",
#         "items": {
#           "type": "object",
#           "properties": {
#             "id": {
#               "description": "The ID of the answer.",
#               "example": 9072,
#               "type": "integer",
#               "format": "int64"
#             },
#             "text": {
#               "description": "The text of the answer.",
#               "example": "A X men",
#               "type": "string"
#             },
#             "html": {
#               "description": "The HTML version of the answer text.",
#               "example": "",
#               "type": "string"
#             },
#             "comments": {
#               "description": "Comments for this specific answer.",
#               "example": "",
#               "type": "string"
#             },
#             "comments_html": {
#               "description": "The HTML version of the comments for this answer.",
#               "example": "",
#               "type": "string"
#             },
#             "weight": {
#               "description": "The weight of the answer. 100 indicates a correct answer, 0 indicates incorrect.",
#               "example": 100.0,
#               "type": "number"
#             }
#           }
#         }
#       },
#       "variables": {
#         "description": "Variables for calculated questions. Null for other question types.",
#         "type": "array"
#       },
#       "formulas": {
#         "description": "Formulas for calculated questions. Null for other question types.",
#         "type": "array"
#       },
#       "answer_tolerance": {
#         "description": "The tolerance for numerical answers. Null for non-numerical question types.",
#         "type": "string"
#       },
#       "formula_decimal_places": {
#         "description": "The number of decimal places for formula results. Null for non-calculated question types.",
#         "type": "integer"
#       },
#       "matches": {
#         "description": "Matching pairs for matching questions. Null for other question types.",
#         "type": "array"
#       },
#       "matching_answer_incorrect_matches": {
#         "description": "Incorrect match options for matching questions. Null for other question types.",
#         "type": "array"
#       }
#     }
#   }
#
class AssessmentQuestionBanksController < ApplicationController
  include Api::V1::AssessmentQuestionBank
  include Api::V1::QuizQuestion

  before_action :require_context, only: [:index]
  before_action :require_bank, only: [:show, :questions]

  # @API List question banks
  #
  # Returns the paginated list of question banks for a given context.
  #
  # @argument context_type [Required, String, "Course"|"Account"]
  #   The type of context. Must be either "Course" or "Account".
  #
  # @argument context_id [Required, Integer]
  #   The id of the context.
  #
  # @argument include_question_count [Boolean]
  #   Whether to include the number of questions in each bank.
  #
  # @example_request
  #   curl 'https://<canvas>/api/v1/question_banks?context_type=Course&context_id=1' \
  #        -H 'Authorization: Bearer <token>'
  #
  # @returns [AssessmentQuestionBank]
  def index
    if authorized_action(@context, @current_user, :read_question_banks)
      @banks = @context.assessment_question_banks.active
      render json: question_banks_json(@banks,
                                       @current_user,
                                       session,
                                       include_question_count: params[:include_question_count])
    end
  end

  # @API Get a single question bank
  #
  # Returns the question bank with the given id
  #
  # @argument id [Required, Integer]
  #   The question bank unique identifier.
  #
  # @argument include_question_count [Boolean]
  #   Whether to include the number of questions in the bank.
  #
  # @returns AssessmentQuestionBank
  def show
    if authorized_action(@bank, @current_user, :read)
      render json: question_bank_json(@bank,
                                      @current_user,
                                      session,
                                      include_question_count: params[:include_question_count])
    end
  end

  # @API List assessment questions for a question bank
  #
  # Returns the paginated list of assessment questions in this bank.
  #
  # @argument id [Required, Integer]
  #   The question bank unique identifier.
  #
  # @example_request
  #   curl 'https://<canvas>/api/v1/question_banks/:id/questions' \
  #        -H 'Authorization: Bearer <token>'
  #
  # @returns [AssessmentQuestion]
  def questions
    if authorized_action(@bank, @current_user, :read)
      # Set @context for the assessment question helper
      @context = @bank.context

      # Get assessment questions from this bank
      # Order by position for consistent ordering
      scope = @bank.assessment_questions.active.order(:position)

      # Setup pagination
      api_route = api_v1_question_bank_questions_path(@bank)
      assessment_questions = Api.paginate(scope, self, api_route)

      # Render using the assessment question JSON serializer
      render json: questions_json(assessment_questions,
                                  @current_user,
                                  session,
                                  includes: parse_includes)
    end
  end

  private

  def parse_includes
    Array(params[:include] || []).map(&:to_sym)
  end

  def require_context
    context_type = params[:context_type]
    context_id = params[:context_id]

    unless context_type.present? && context_id.present?
      return render json: { errors: "context_type and context_id are required" }, status: :bad_request
    end

    @context = case context_type
               when "Course"
                 Course.find(context_id)
               when "Account"
                 Account.find(context_id)
               else
                 return render json: { errors: "context_type must be 'Course' or 'Account'" }, status: :bad_request
               end
  rescue ActiveRecord::RecordNotFound
    render_unauthorized_action
  end

  def require_bank
    @bank = AssessmentQuestionBank.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_unauthorized_action
  end
end
