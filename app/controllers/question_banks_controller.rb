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
  before_filter :require_context, :except => :bookmark
  add_crumb(proc { t('#crumbs.question_banks', "Question Banks") }, :except => :bookmark) { |c| c.send :named_context_url, c.instance_variable_get("@context"), :context_question_banks_url }

  include Api::V1::Outcome

  def index
    if @context == @current_user || authorized_action(@context, @current_user, :manage_assignments)
      @question_banks = @context.assessment_question_banks.active.except(:includes).all
      if params[:include_bookmarked] == '1'
        @question_banks += @current_user.assessment_question_banks.active
      end
      if params[:inherited] == '1' && @context != @current_user && @context.grants_right?(@current_user, :read_question_banks)
        @question_banks += @context.inherited_assessment_question_banks.active
      end
      @question_banks = @question_banks.select{|b| b.grants_right?(@current_user, :manage) } if params[:managed] == '1'
      @question_banks = Canvas::ICU.collate_by(@question_banks.uniq) { |b| b.title || CanvasSort::Last }
      respond_to do |format|
        format.html
        format.json { render :json => @question_banks.map{ |b| b.as_json(methods: [:cached_context_short_name, :assessment_question_count]) }}
      end
    end
  end

  def questions
    find_bank(params[:question_bank_id], params[:inherited] == '1') do
      @questions = @bank.assessment_questions.active
      url = polymorphic_url([@context, :question_bank_questions])
      @questions = Api.paginate(@questions, self, url, default_per_page: 50)
      render :json => {:pages => @questions.total_pages, :questions => @questions}
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
    js_env :ROOT_OUTCOME_GROUP => outcome_group_json(@context.root_outcome_group, @current_user, session)

    add_crumb(@bank.title)
    if authorized_action(@bank, @current_user, :read)
      @alignments = Canvas::ICU.collate_by(@bank.learning_outcome_alignments) { |a| a.learning_outcome.short_description }
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
      @questions = @bank.assessment_questions.where(:id => ids)
      if params[:move] != '1'
        attributes = @questions.columns.map(&:name) - %w{id created_at updated_at assessment_question_bank_id}
        connection = @questions.connection
        attributes = attributes.map { |attr| connection.quote_column_name(attr) }
        now = connection.quote(Time.now.utc)
        connection.execute(
            "INSERT INTO assessment_questions (#{(%w{assessment_question_bank_id created_at updated_at} + attributes).join(', ')})" +
            @questions.select(([@new_bank.id, now, now] + attributes).join(', ')).to_sql)
      else
        @questions.update_all(:assessment_question_bank_id => @new_bank)
      end

      [ @bank, @new_bank ].each(&:touch)

      render :json => {}
    end
  end

  def create
    if authorized_action(@context.assessment_question_banks.scoped.new, @current_user, :create)
      @bank = @context.assessment_question_banks.build(params[:assessment_question_bank])
      respond_to do |format|
        if @bank.save
          @bank.bookmark_for(@current_user)
          flash[:notice] = t :bank_success, "Question bank successfully created!"
          format.html { redirect_to named_context_url(@context, :context_question_banks_url) }
          format.json { render :json => @bank }
        else
          flash[:error] = t :bank_fail, "Question bank failed to create."
          format.html { redirect_to named_context_url(@context, :context_question_banks_url) }
          format.json { render :json => @bank.errors, :status => :bad_request }
        end
      end
    end
  end

  def bookmark
    @bank = AssessmentQuestionBank.find(params[:question_bank_id])

    if params[:unbookmark] == "1"
      render :json => @bank.bookmark_for(@current_user, false)
    elsif authorized_action(@bank, @current_user, :update)
      render :json => @bank.bookmark_for(@current_user)
    end
  end

  def update
    @bank = @context.assessment_question_banks.find(params[:id])
    if authorized_action(@bank, @current_user, :update)
      if @bank.update_attributes(params[:assessment_question_bank])
        @bank.reload
        render :json => @bank.as_json(:include => {:learning_outcome_alignments => {:include => {:learning_outcome => {:include_root => false}}}})
      else
        render :json => @bank.errors, :status => :bad_request
      end
    end
  end

  def destroy
    @bank = @context.assessment_question_banks.find(params[:id])
    if authorized_action(@bank, @current_user, :delete)
      @bank.destroy
      render :json => @bank
    end
  end
end
