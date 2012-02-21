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

class OutcomesController < ApplicationController
  before_filter :require_context, :except => [:build_outcomes]
  add_crumb(proc { t "#crumbs.outcomes", "Outcomes" }, :except => [:destroy, :build_outcomes]) { |c| c.send :named_context_url, c.instance_variable_get("@context"), :context_outcomes_path }
  before_filter { |c| c.active_tab = "outcomes" }
  
  def index
    if authorized_action(@context, @current_user, :read)
      return unless tab_enabled?(@context.class::TAB_OUTCOMES)
      @root_outcome_group = LearningOutcomeGroup.default_for(@context)
      @outcomes = @context.learning_outcomes
    end
  end
  
  def show
    @outcome = @context.learning_outcomes.find(params[:id])
    if authorized_action(@context, @current_user, :manage_outcomes)
      codes = [@context].map(&:asset_string)
      if @context.is_a?(Account)
        if @context == @outcome.context
          codes = "all"
        else
          codes = @context.all_courses.scoped({:select => 'id'}).map(&:asset_string)
        end
      end
      @tags = @outcome.content_tags.active.for_context(@context)
      add_crumb(@outcome.short_description, named_context_url(@context, :context_outcome_url, @outcome.id))
      @results = @outcome.learning_outcome_results.for_context_codes(codes).custom_ordering(params[:sort]).paginate(:page => params[:page], :per_page => 10)
    end
  end

  def details
    @outcome = @context.learning_outcomes.find(params[:outcome_id])
    if authorized_action(@context, @current_user, :read)
      @outcome.tie_to(@context)
      render :json => @outcome.to_json(
        :methods => :artifacts_count_for_tied_context,
        :user_content => %w(description))
    end
  end

  def outcome_results
    @outcome = @context.learning_outcomes.find(params[:outcome_id])
    if authorized_action(@context, @current_user, :read)
      codes = [@context].map(&:asset_string)
      if @context.is_a?(Account)
        if @context == @outcome.context
          codes = "all"
        else
          codes = @context.all_courses.scoped({:select => 'id'}).map(&:asset_string)
        end
      end
      @results = @outcome.learning_outcome_results.for_context_codes(codes).custom_ordering(params[:sort]).paginate(:page => params[:page], :per_page => 10)
      render :json => @results.to_json
    end
  end
  
  def user_outcome_results
    user_id = params[:user_id]
    if @context.is_a?(User)
      @user = @context
    elsif @context.is_a?(Course)
      @user = @context.users.find(user_id)
    else
      @user = @context.all_users.find(user_id)
    end
    if authorized_action(@context, @current_user, :manage)
      if @user == @context
        @outcomes = LearningOutcome.has_result_for(@user).active
      else
        @root_outcome_group = LearningOutcomeGroup.default_for(@context)
        @outcomes = @root_outcome_group.sorted_all_outcomes
      end
      @results = LearningOutcomeResult.for_user(@user).for_outcome_ids(@outcomes.map(&:id)) #.for_context_codes(@codes)
      @results_for_outcome = @results.group_by(&:learning_outcome_id)
    end
  end
  
  def list
    if authorized_action(@context, @current_user, :manage_outcomes)
      @account_contexts = @context.associated_accounts rescue []
      @current_outcomes = @context.learning_outcomes
      @outcomes = LearningOutcome.available_in_context(@context)
      if params[:unused]
        @outcomes -= @current_outcomes
      end
      render :json => @outcomes.to_json(:methods => :cached_context_short_name)
    end
  end
  
  # as in, add existing outcome from another context to this context
  # who named this method, anyway?  spaz.
  def add_outcome
    if authorized_action(@context, @current_user, :manage_outcomes)
      @account_contexts = @context.associated_accounts.uniq rescue []
      codes = @account_contexts.map(&:asset_string)
      @outcome = LearningOutcome.for_context_codes(codes).find(params[:learning_outcome_id])
      @group = @context.learning_outcome_groups.find(params[:learning_outcome_group_id])
      @tag = @group.add_item(@outcome)
      render :json => @outcome.to_json(:methods => :cached_context_short_name, :permissions => {:user => @current_user, :session => session})
    end
  end
  
  def add_outcome_group
    if authorized_action(@context, @current_user, :manage_outcomes)
      @group = Account.template.learning_outcome_groups.find(params[:learning_outcome_group_id])
      @root_outcome_group = LearningOutcomeGroup.default_for(@context)
      @tag = @root_outcome_group.add_item(@group, params)
      render :json => @group.to_json(:include => :learning_outcomes)
    end
  end
  
  def align
    if authorized_action(@context, @current_user, :manage_outcomes)
      @outcome = @context.learning_outcomes.find(params[:outcome_id])
      @asset = @context.find_asset(params[:asset_string])
      mastery_type = @asset.is_a?(Assignment) ? "points" : "none"
      @tag = @outcome.align(@asset, @context, :mastery_type => mastery_type) if @asset
      render :json => @tag.to_json(:include => :learning_outcome)
    end
  end
  
  def alignment_redirect
    if authorized_action(@context, @current_user, :read)
      # TODO LearningOutcome.available_in_context is a horrible horrible
      # method. It runs way too many queries, and then throws most of the
      # results away. But it has the semantics we want, and will need to be
      # fixed for its other use cases anyways, so we'll use it here and in
      # remove_alignment.
      @outcome = LearningOutcome.available_in_context(@context, [params[:outcome_id].to_i]).first
      @tag = @outcome.content_tags.find(params[:id])
      content_tag_redirect(@context, @tag, :context_outcomes_url)
    end
  end
  
  def remove_alignment
    if authorized_action(@context, @current_user, :manage_outcomes)
      @outcome = LearningOutcome.available_in_context(@context, [params[:outcome_id].to_i]).first
      @tag = @outcome.content_tags.find(params[:id])
      @tag = @outcome.remove_alignment(@tag.content, @context)
      render :json => @tag.to_json(:include => :learning_outcome)
    end
  end
  
  def outcome_result
    if authorized_action(@context, @current_user, :manage_outcomes)
      @outcome = @context.learning_outcomes.find(params[:outcome_id])
      @result = @outcome.learning_outcome_results.find(params[:id])
      if authorized_action(@result.context, @current_user, :manage_outcomes)
        if @result.artifact.is_a?(Submission)
          @submission = @result.artifact
          redirect_to named_context_url(@result.context, :context_assignment_submission_url, @submission.assignment_id, @submission.user_id)
        elsif @result.artifact.is_a?(RubricAssessment) && @result.artifact.artifact && @result.artifact.artifact.is_a?(Submission)
          @submission = @result.artifact.artifact
          redirect_to named_context_url(@result.context, :context_assignment_submission_url, @submission.assignment_id, @submission.user_id)
        elsif @result.artifact.is_a?(QuizSubmission) && @result.associated_asset
          @submission = @result.artifact
          @question = @result.associated_asset
          if @submission.attempt <= @result.attempt
            @submission_version = @submission
          else
            @submission_version = @submission.submitted_versions.detect{|s| s.attempt >= @result.attempt }
          end
          question = @submission.quiz_data.detect{|q| q['assessment_question_id'] == @question.data[:id] }
          question_id = (question && question['id']) || @question.data[:id]
          redirect_to named_context_url(@result.context, :context_quiz_history_url, @submission.quiz_id, :quiz_submission_id => @submission.id, :version => @submission_version.version_number, :anchor => "question_#{question_id}")
        else
          flash[:error] = "Unrecognized artifact type: #{@result.try(:artifact_type) || 'nil'}"
          redirect_to named_context_url(@context, :context_outcome_url, @outcome.id)
        end
      end
    end
  end
  
  def reorder_alignments
    if authorized_action(@context, @current_user, :manage_outcomes)
      @outcome = @context.learning_outcomes.find(params[:outcome_id])
      @tags = @outcome.reorder_alignments(@context, params[:order].split(","))
      render :json => @tags.to_json(:include => :learning_outcome)
    end
  end
  
  def update_outcomes_for_asset
    if authorized_action(@context, @current_user, :manage_outcomes)
      @asset = @context.find_asset(params[:asset_string])
      @assignment = @asset.respond_to?(:assignment) && @asset.assignment
      @tags = ContentTag.learning_outcome_tags_for(@asset).select{|t| !t.rubric_association_id }
      @outcomes = @context.learning_outcomes.active
      outcome_ids = params[:outcome_ids].split(",").map(&:to_i)
      selected_outcomes = @outcomes.select{|o| outcome_ids.include?(o.id) }
      outcome_ids = selected_outcomes.map(&:id)
      existing_tags = @tags.select{|t| outcome_ids.include?(t.learning_outcome_id) }
      existing_outcome_ids = existing_tags.map(&:learning_outcome_id).uniq
      tags_to_delete = @tags.select{|t| !existing_outcome_ids.include?(t.learning_outcome_id) }
      new_outcome_ids = outcome_ids - existing_outcome_ids
      new_outcomes = @outcomes.select{|o| new_outcome_ids.include?(o.id) }
      tags_to_delete.each{|t| t.destroy }
      new_outcomes.each do |outcome|
        outcome.align(@assignment || @asset, @context, @assignment ? "points" : "none")
      end
      if @assignment && params[:mastery_score] && !params[:mastery_score].empty?
        @assignment.update_attribute(:mastery_score, params[:mastery_score].to_f)
      end
      @all_tags = []
      if @asset
        @all_tags = ContentTag.learning_outcome_tags_for(@asset)
      end
      @asset.class.update_all({:updated_at => Time.now.utc}, {:id => @asset.id})
      render :json => @all_tags.to_json(:include => :learning_outcome)
    end
  end
  
  def outcomes_for_asset
    if authorized_action(@context, @current_user, :read)
      @asset = @context.find_asset(params[:asset_string])
      @tags = []
      if @asset
        @tags = ContentTag.learning_outcome_tags_for(@asset)
      end
      render :json => @tags.to_json(:include => :learning_outcome)
    end
  end
  
  def create
    if authorized_action(@context, @current_user, :manage_outcomes)
      if params[:learning_outcome_group_id].present?
        @outcome_group = @context.learning_outcome_groups.find_by_id(params[:learning_outcome_group_id])
      end
      @outcome_group ||= LearningOutcomeGroup.default_for(@context)
      @outcome = @context.created_learning_outcomes.build(params[:learning_outcome])
      respond_to do |format|
        if @outcome.save
          @outcome_group.add_item(@outcome)
          flash[:notice] = t :successful_outcome_creation, "Outcome successfully created!"
          format.html { redirect_to named_context_url(@context, :context_outcomes_url) }
          format.json { render :json => @outcome.to_json }
        else
          flash[:error] = t :failed_outcome_creation, "Outcome creation failed"
          format.html { redirect_to named_context_url(@context, :context_outcomes_url) }
          format.json { render :json => @outcome.errors.to_json, :status => :bad_request }
        end
      end
    end
  end
  
  def update
    if authorized_action(@context, @current_user, :manage_outcomes)
      @outcome = @context.learning_outcomes.find(params[:id])
      respond_to do |format|
      
        if @outcome.update_attributes(params[:learning_outcome])
          flash[:notice] = t :successful_outcome_update, "Outcome successfully updated!"
          format.html { redirect_to named_context_url(@context, :context_outcomes_url) }
          format.json { render :json => @outcome.to_json }
        else
          flash[:error] = t :failed_outcome_update, "Outcome update failed"
          format.html { redirect_to named_context_url(@context, :context_outcomes_url) }
          format.json { render :json => @outcome.errors.to_json, :statue => :bad_request }
        end
      end
    end
  end
  
  def destroy
    if authorized_action(@context, @current_user, :manage_outcomes)
      @outcome = @context.learning_outcomes.find_by_id(params[:id]) if params[:id].present?
      @outcome ||= @context.learning_outcome_tags.find_by_learning_outcome_id(params[:id]) if params[:id].present?
      respond_to do |format|
        if @outcome
          if @outcome.context_code == @context.asset_string
            @outcome.destroy
            flash[:notice] = t :successful_outcome_delete, "Outcome successfully deleted"
          else
            @tags = LearningOutcomeGroup.default_for(@context).all_tags_for_context.select{|t| t.content_type == 'LearningOutcome' && t.content_id == @outcome.id }
            @tags.each{|t| t.destroy }
            flash[:notice] = t :successful_outcome_removal, "Outcome successfully removed"
          end
          format.html { redirect_to named_context_url(@context, :context_outcomes_url) }
          format.json { render :json => @outcome.to_json }
        else
          flash[:notice] = t :missing_outcome, "Couldn't find that learning outcome"
          format.html { redirect_to named_context_url(@context, :context_outcomes_url) }
          format.json { render :json => {:errors => {:base => t(:missing_outcome, "Couldn't find that learning outcome")}}, :status => :bad_request }
        end
      end
    end
  end
end
