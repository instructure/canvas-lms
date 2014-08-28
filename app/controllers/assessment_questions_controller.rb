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

class AssessmentQuestionsController < ApplicationController
  include Api::V1::QuizQuestion

  before_filter :require_context
  before_filter :require_bank
  def create
    if authorized_action(@bank.assessment_questions.new, @current_user, :create)
      params[:assessment_question] ||= {}
      params[:assessment_question].delete(:assessment_question_bank_id)
      params[:assessment_question][:form_question_data] ||= params[:question]
      @question = @bank.assessment_questions.build(params[:assessment_question])
      if @question.with_versioning(&:save)
        render json: question_json(@question, @current_user, session, [:assessment_question])
      else
        render :json => @question.errors, :status => :bad_request
      end
    end
  end
  
  def update
    @question = @bank.assessment_questions.find(params[:id])
    if authorized_action(@question, @current_user, :update)
      params[:assessment_question] ||= {}
      # changing the question bank id needs to use the move action, below
      params[:assessment_question].delete(:assessment_question_bank_id)
      params[:assessment_question][:form_question_data] ||= params[:question]
      @question.edited_independent_of_quiz_question
      if @question.with_versioning { @question.update_attributes(params[:assessment_question]) }
        render json: question_json(@question, @current_user, session, [:assessment_question])
      else
        render :json => @question.errors, :status => :bad_request
      end
    end
  end
  
  def destroy
    @question = @bank.assessment_questions.find(params[:id])
    if authorized_action(@question, @current_user, :delete)
      @question.destroy
      render :json => @question
    end
  end
  
  private
  def require_bank
    @bank = @context.assessment_question_banks.active.find(params[:question_bank_id])
  end
end
