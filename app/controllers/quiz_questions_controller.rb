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

class QuizQuestionsController < ApplicationController
  before_filter :require_context, :get_quiz

  def show
    if authorized_action(@quiz, @current_user, :update)
      @question = @quiz.quiz_questions.active.find(params[:id])
      render :json => @question.as_json(:include => :assessment_question)
    end
  end
  
  def create
    if authorized_action(@quiz, @current_user, :update)
      if params[:existing_questions]
        return add_questions
      end
      question_data = params[:question]
      question_data ||= {}
      if question_data[:quiz_group_id]
        @group = @quiz.quiz_groups.find(question_data[:quiz_group_id])
      end
      @question = @quiz.quiz_questions.create(:quiz_group => @group, :question_data => question_data)
      @quiz.did_edit if @quiz.created?
      
      render :json => @question.as_json(:include => :assessment_question)
    end
  end
  
  def add_questions
    find_bank(params[:assessment_question_bank_id]) do
      @assessment_questions = @bank.assessment_questions.active.find_all_by_id(params[:assessment_questions_ids].split(",")).compact
      @group = @quiz.quiz_groups.find_by_id(params[:quiz_group_id]) if params[:quiz_group_id].to_i > 0
      @questions = @quiz.add_assessment_questions(@assessment_questions, @group)
      render :json => @questions
    end
  end
  protected :add_questions

  def update
    if authorized_action(@quiz, @current_user, :update)
      @question = @quiz.quiz_questions.active.find(params[:id])
      question_data = params[:question]
      question_data[:regrade_user] = @current_user
      question_data ||= {}

      if question_data[:quiz_group_id]
        @group = @quiz.quiz_groups.find(question_data[:quiz_group_id])
        if question_data[:quiz_group_id] != @question.quiz_group_id
          @question.quiz_group_id = question_data[:quiz_group_id]
          @question.position = @group.quiz_questions.active.length
        end
      end

      @question.question_data = question_data
      @question.save
      @quiz.did_edit if @quiz.created?
      
      render :json => @question.as_json(:include => :assessment_question)
    end
  end

  def destroy
    if authorized_action(@quiz, @current_user, :update)
      @question = @quiz.quiz_questions.active.find(params[:id])
      @question.destroy
      render :json => @question
    end
  end
  
  def get_quiz
    @quiz = @context.quizzes.find(params[:quiz_id])
  end
  private :get_quiz
end
