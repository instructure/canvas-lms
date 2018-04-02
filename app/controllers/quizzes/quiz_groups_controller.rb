#
# Copyright (C) 2011 - present Instructure, Inc.
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

# @API Quiz Question Groups
#
# API for accessing information on quiz question groups
#
# @model QuizGroup
#     {
#       "id": "QuizGroup",
#       "required": ["id", "quiz_id"],
#       "properties": {
#         "id": {
#           "description": "The ID of the question group.",
#           "example": 1,
#           "type": "integer",
#           "format": "int64"
#         },
#         "quiz_id": {
#           "description": "The ID of the Quiz the question group belongs to.",
#           "example": 2,
#           "type": "integer",
#           "format": "int64"
#         },
#         "name": {
#           "description": "The name of the question group.",
#           "example": "Fraction questions",
#           "type": "string"
#         },
#         "pick_count": {
#           "description": "The number of questions to pick from the group to display to the student.",
#           "example": 3,
#           "type": "integer",
#           "format": "int64"
#         },
#         "question_points": {
#           "description": "The amount of points allotted to each question in the group.",
#           "example": 10,
#           "type": "integer",
#           "format": "int64"
#         },
#         "assessment_question_bank_id": {
#           "description": "The ID of the Assessment question bank to pull questions from.",
#           "example": 2,
#           "type": "integer",
#           "format": "int64"
#         },
#         "position": {
#           "description": "The order in which the question group will be retrieved and displayed.",
#           "example": 1,
#           "type": "integer",
#           "format": "int64"
#         }
#       }
#     }
#
class Quizzes::QuizGroupsController < ApplicationController
  include Api::V1::QuizGroup
  include ::Filters::Quizzes

  before_action :require_context, :require_quiz

  # @API Get a single quiz group
  #
  # Returns details of the quiz group with the given id.
  #
  # @returns QuizGroup
  def show
    if authorized_action(@quiz, @current_user, :read)
      @group = @quiz.quiz_groups.find(params[:id])
      render json: quiz_group_json(@group, @context, @current_user, session)
    end
  end

  # @API Create a question group
  #
  # Create a new question group for this quiz
  #
  # <b>201 Created</b> response code is returned if the creation was successful.
  #
  # @argument quiz_groups[][name] [String]
  #   The name of the question group.
  #
  # @argument quiz_groups[][pick_count] [Integer]
  #   The number of questions to randomly select for this group.
  #
  # @argument quiz_groups[][question_points] [Integer]
  #   The number of points to assign to each question in the group.
  #
  # @argument quiz_groups[][assessment_question_bank_id] [Integer]
  #   The id of the assessment question bank to pull questions from.
  #
  # @example_response
  #  {
  #    "quiz_groups": [QuizGroup]
  #  }
  def create
    if authorized_action(@quiz, @current_user, :update)
      @quiz.did_edit if @quiz.created?

      quiz_group_params = params[:quiz_groups][0].permit(:name, :pick_count, :question_points, :assessment_question_bank_id)
      bank_id = quiz_group_params.delete(:assessment_question_bank_id)
      bank = find_bank(bank_id) if bank_id.present?
      quiz_group_params[:assessment_question_bank_id] = bank_id if bank

      @group = @quiz.quiz_groups.build
      if update_api_quiz_group(@group, quiz_group_params)
        render :json   => quiz_groups_compound_json([@group], @context, @current_user, session),
               :status => :created
      else
        render json: format_errors(@group), status: :unprocessable_entity
      end
    end
  end

  # @API Update a question group
  #
  # Update a question group
  #
  # @argument quiz_groups[][name] [String]
  #   The name of the question group.
  #
  # @argument quiz_groups[][pick_count] [Integer]
  #   The number of questions to randomly select for this group.
  #
  # @argument quiz_groups[][question_points] [Integer]
  #   The number of points to assign to each question in the group.
  #
  # @example_response
  #  {
  #    "quiz_groups": [QuizGroup]
  #  }
  def update
    if authorized_action(@quiz, @current_user, :update)
      @group = @quiz.quiz_groups.find(params[:id])
      @quiz.did_edit if @quiz.created?

      quiz_group_params = params[:quiz_groups][0].permit(:name, :pick_count, :question_points)
      if update_api_quiz_group(@group, quiz_group_params)
        render :json => quiz_groups_compound_json([@group], @context, @current_user, session)
      else
        render :json => format_errors(@group), :status => :unprocessable_entity
      end
    end
  end

  # @API Delete a question group
  #
  # Delete a question group
  #
  # <b>204 No Content<b> response code is returned if the deletion was successful.
  def destroy
    if authorized_action(@quiz, @current_user, :update)
      @group = @quiz.quiz_groups.find(params[:id])
      @group.destroy

      head :no_content
    end
  end

  # @API Reorder question groups
  #
  # Change the order of the quiz questions within the group
  #
  # @argument order[][id] [Required, Integer]
  #   The associated item's unique identifier
  #
  # @argument order[][type] [String, "question"]
  #   The type of item is always 'question' for a group
  #
  # <b>204 No Content<b> response code is returned if the reorder was successful.
  def reorder
    if authorized_action(@quiz, @current_user, :update)
      @group = @quiz.quiz_groups.find(params[:id])
      Quizzes::QuizSortables.new(:group => @group, :order => params[:order]).reorder!

      head :no_content
    end
  end
  private

  def format_errors(group)
    group.errors.each_with_object({errors: {}}) do |e, json|
      json[:errors][e.first] = e.last
    end
  end

end
