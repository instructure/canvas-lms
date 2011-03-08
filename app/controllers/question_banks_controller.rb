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

class QuestionBanksController < ApplicationController
  before_filter :require_context
  add_crumb("Question Banks") { |c| c.send :named_context_url, c.instance_variable_get("@context"), :context_question_banks_url }
  
  def index
    @unfiled_questions = []
    if @context != @current_user && @context.respond_to?(:assessment_questions)
      @unfiled_questions = @context.assessment_questions.select{|q| q.assessment_question_bank_id == nil }.sort_by{|q| q.created_at }.reverse
    end
    if @context == @current_user || authorized_action(@context, @current_user, :manage_assignments)
      if !@unfiled_questions.empty?
        @bank = @context.assessment_question_banks.find_or_create_by_title_and_workflow_state(AssessmentQuestionBank::DEFAULT_UNFILED_TITLE, 'active')
        AssessmentQuestion.update_all(['assessment_question_bank_id=?, position=id', @bank.id], {:context_type => @context.class.to_s, :context_id => @context.id, :assessment_question_bank_id => nil})
      end
      @question_banks = @context.assessment_question_banks.active.include_questions.sort_by{|b| b.title || "zzz" }
      if params[:managed] == '1'
        @question_banks += @current_user.assessment_question_banks.active if @current_user
        @question_banks = @question_banks.uniq.sort_by{|b| b.title || "zzz" }.select{|b| b.grants_right?(@current_user, nil, :manage) }
      elsif params[:include_bookmarked] == '1'
        @question_banks += @current_user.assessment_question_banks.active if @current_user
        @question_banks = @question_banks.uniq.sort_by{|b| b.title || "zzz" }
      end
      respond_to do |format|
        format.html
        format.json { render :json => @question_banks.to_json(:methods => [:cached_context_short_name, :assessment_question_count]) }
      end
    end
  end
  
  def questions
    @bank = @context.assessment_question_banks.find(params[:question_bank_id])
    if authorized_action(@bank, @current_user, :read)
      @questions = @bank.assessment_questions.active.paginate(:per_page => 50, :page => params[:page])
      render :json => {:pages => @questions.total_pages, :questions => @questions}.to_json
    end
  end
  
  def reorder
    @bank = @context.assessment_question_banks.find(params[:question_bank_id])
    if authorized_action(@bank, @current_user, :update)
      @bank.assessment_questions.active.first.update_order(params[:order].split(','))
      render :json => {:reorder => true}
    end
  end
  
  def show
    @bank = @context.assessment_question_banks.find(params[:id])
    add_crumb(@bank.title)
    if authorized_action(@bank, @current_user, :read)
      @outcome_tags = @bank.learning_outcome_tags.sort_by{|t| t.learning_outcome.short_description.downcase }
      @questions = @bank.assessment_questions.active.paginate(:per_page => 50, :page => 1)
    end
  end
  
  def move_questions
    @bank = @context.assessment_question_banks.find(params[:question_bank_id])
    @new_bank = AssessmentQuestionBank.find(params[:assessment_question_bank_id])
    if authorized_action(@bank, @current_user, :update) && authorized_action(@new_bank, @current_user, :manage)
      ids = []
      params[:questions].each do |key, value|
        ids << key.to_i if value != '0' && key.to_i != 0
      end
      @questions = @bank.assessment_questions.find_all_by_id(ids)
      @new_questions = []
      @questions.each do |question|
        new_question = question
        if params[:move] != '1'
          new_question = question.clone_for(@new_bank)
        end
        new_question.context = @new_bank.context
        new_question.assessment_question_bank = @new_bank
        new_question.save
        @new_questions << new_question
      end
      render :json => @new_questions.to_json
    end
  end
  
  def create
    if authorized_action(@context.assessment_question_banks.new, @current_user, :create)
      @bank = @context.assessment_question_banks.build(params[:assessment_question_bank])
      respond_to do |format|
        if @bank.save
          @bank.bookmark_for(@current_user)
          flash[:notice] = "Question bank successfully created!"
          format.html { redirect_to named_context_url(@context, :context_question_banks_url) }
          format.json { render :json => @bank.to_json }
        else
          flash[:error] = "Question bank failed to create."
          format.html { redirect_to named_context_url(@context, :context_question_banks_url) }
          format.json { render :json => @bank.errors.to_json, :status => :bad_request }
        end
      end
    end
  end
  
  def bookmark
    @bank = @context.assessment_question_banks.find(params[:question_bank_id])
    if authorized_action(@bank, @current_user, :update)
      render :json => @bank.bookmark_for(@current_user, params[:unbookmark] != '1').to_json
    end
  end
  
  def update
    @bank = @context.assessment_question_banks.find(params[:id])
    if authorized_action(@bank, @current_user, :update)
      if @bank.update_attributes(params[:assessment_question_bank])
        @bank.reload
        render :json => @bank.to_json(:include => {:learning_outcome_tags => {:include => :learning_outcome}})
      else
        render :json => @bank.errors.to_json, :status => :bad_request
      end
    end
  end
  
  def destroy
    @bank = @context.assessment_question_banks.find(params[:id])
    if authorized_action(@bank, @current_user, :delete)
      @bank.destroy
      render :json => @bank.to_json
    end
  end
end
