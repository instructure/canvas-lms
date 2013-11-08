#
# Copyright (C) 2011 Instructure, Inc.
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
# @beta
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
#           "example": 2,
#           "type": "integer",
#           "format": "int64"
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
class QuizGroupsController < ApplicationController
  include Api::V1::QuizGroup

  before_filter :require_context, :get_quiz

  # @API Create a question group
  # @beta
  #
  # Create a new question group for this quiz
  #
  # @argument quiz_group[name] [Optional, String]
  #   The name of the question group.
  #
  # @argument quiz_group[pick_count] [Optional, Integer]
  #   The number of questions to randomly select for this group.
  #
  # @argument quiz_group[question_points] [Optional, Integer]
  #   The number of points to assign to each question in the group.
  #
  # @argument quiz_group[assessment_question_bank_id] [Optional, Integer]
  #   The id of the assessment question bank to pull questions from.
  #
  # @returns QuizGroup
  def create
    if authorized_action(@quiz, @current_user, :update)
      @quiz.did_edit if @quiz.created?

      bank_id = params[:quiz_group].delete(:assessment_question_bank_id)
      bank = find_bank(bank_id) if bank_id.present?
      params[:quiz_group][:assessment_question_bank_id] = bank_id if bank

      @group = @quiz.quiz_groups.build
      if update_api_quiz_group(@group, params[:quiz_group])
        render :json => quiz_group_json(@group, @context, @current_user, session)
      else
        render :json => @group.errors, :status => :bad_request
      end
    end
  end

  # @API Update a question group
  # @beta
  #
  # Update a new question group
  #
  # @argument quiz_group[name] [Optional, String]
  #   The name of the question group.
  #
  # @argument quiz_group[pick_count] [Optional, Integer]
  #   The number of questions to randomly select for this group.
  #
  # @argument quiz_group[question_points] [Optional, Integer]
  #   The number of points to assign to each question in the group.
  #
  # @returns QuizGroup
  def update
    if authorized_action(@quiz, @current_user, :update)
      @group = @quiz.quiz_groups.find(params[:id])
      @quiz.did_edit if @quiz.created?

      params[:quiz_group].delete(:assessment_question_bank_id)
      params[:quiz_group].delete(:position) # position is taken care of in reorder

      if update_api_quiz_group(@group, params[:quiz_group])
        render :json => quiz_group_json(@group, @context, @current_user, session)
      else
        render :json => @group.errors, :status => :bad_request
      end
    end
  end

  def destroy
    if authorized_action(@quiz, @current_user, :update)
      @group = @quiz.quiz_groups.find(params[:id])
      @group.destroy
      render :json => @group
    end
  end

  def reorder
    if authorized_action(@quiz, @current_user, :update)
      @group = @quiz.quiz_groups.find(params[:quiz_group_id])
      items = []
      group_questions = @group.quiz_questions.active
      questions = @quiz.quiz_questions.active
      order = params[:order].split(",")
      order.each do |name|
        id = name.gsub(/\Aquestion_/, "").to_i
        obj = questions.detect{|q| q.id == id.to_i }
        obj.quiz_group_id = @group.id
        if obj
          items << obj
          obj.position = items.length
        end
      end
      group_questions.each do |q|
        if !items.include? q
          items << q
          q.position = items.length
        end
      end
      updates = []
      items.each_with_index do |item, idx|
        updates << "WHEN id=#{item.id} THEN #{idx + 1}"
      end
      QuizQuestion.where(:id => items).update_all("quiz_group_id=#{@group.id}, position=CASE #{updates.join(" ")} ELSE id END")
      Quiz.mark_quiz_edited(@quiz.id)
      render :json => {:reorder => true}
    end
  end

  private

  def get_quiz
    @quiz = @context.quizzes.find(params[:quiz_id])
  end
end
