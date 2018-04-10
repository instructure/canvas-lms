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

class RubricsController < ApplicationController
  before_action :require_context
  before_action { |c| c.active_tab = "rubrics" }

  include Api::V1::Outcome

  def index
    permission = @context.is_a?(User) ? :manage : :manage_rubrics
    return unless authorized_action(@context, @current_user, permission)
    js_env :ROOT_OUTCOME_GROUP => get_root_outcome,
      :PERMISSIONS => {
        manage_outcomes: @context.grants_right?(@current_user, session, :manage_outcomes)
      },
      :NON_SCORING_RUBRICS => @domain_root_account.feature_enabled?(:non_scoring_rubrics)
    @rubric_associations = @context.rubric_associations.bookmarked.include_rubric.to_a
    @rubric_associations = Canvas::ICU.collate_by(@rubric_associations.select(&:rubric_id).uniq(&:rubric_id)) { |r| r.rubric.title }
    @rubrics = @rubric_associations.map(&:rubric)
    @context.is_a?(User) ? render(:action => 'user_index') : render
  end

  def show
    permission = @context.is_a?(User) ? :manage : :manage_rubrics
    return unless authorized_action(@context, @current_user, permission)
    if (id = params[:id]) =~ Api::ID_REGEX
      js_env :ROOT_OUTCOME_GROUP => get_root_outcome
      @rubric_association = @context.rubric_associations.bookmarked.where(rubric_id: params[:id]).first
      raise ActiveRecord::RecordNotFound unless @rubric_association
      @actual_rubric = @rubric_association.rubric
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  # @API Create a single rubric
  # Returns the rubric with the given id.
  # @argument id [Integer]
  #   The id of the rubric
  # @argument rubric_association_id [Integer]
  #   The id of the object with which this rubric is associated
  # @argument rubric[title] [String]
  # @argument rubric[free_form_criterion_comments] [Boolean]
  # @argument rubric_association[association_id] [Integer]
  #   The id of the object with which this rubric is associated
  # @argument rubric_association[association_type] ["Assignment"|"Course"|"Account"]
  #   The type of object this rubric is associated with
  # @argument rubric_association[use_for_grading] [Boolean]
  # @argument rubric_association[hide_score_total] [Boolean]
  # @argument rubric_association[purpose] [String]
  # @argument rubric[criteria] [Hash]
  #   An indexed Hash of RubricCriteria objects where the keys are integer ids and the values are the RubricCriteria objects
  # @returns Rubric

  def create
    update
  end

  # This controller looks yucky (and is yucky) because it handles a funky logic.
  # If you try to update a rubric that is being used in more than one place,
  # instead of updating that rubric this will create a new rubric based on
  # the old rubric and return that one instead.  If you pass it a rubric_association_id
  # parameter, then it will point the rubric_association to the new rubric
  # instead of the old one.


  # @API Update a single rubric
  # Returns the rubric with the given id.
  # @argument id [Integer]
  #   The id of the rubric
  # @argument rubric_association_id [Integer]
  #   The id of the object with which this rubric is associated
  # @argument rubric[title] [String]
  # @argument rubric[free_form_criterion_comments] [Boolean]
  # @argument rubric[skip_updating_points_possible] [Boolean]
  #   Whether or not to update the points possible
  # @argument rubric_association[association_id] [Integer]
  #   The id of the object with which this rubric is associated
  # @argument rubric_association[association_type] ["Assignment"|"Course"|"Account"]
  #   The type of object this rubric is associated with
  # @argument rubric_association[use_for_grading] [Boolean]
  # @argument rubric_association[hide_score_total] [Boolean]
  # @argument rubric_association[purpose] [String]
  # @argument rubric[criteria] [Hash]
  #   An indexed Hash of RubricCriteria objects where the keys are integer ids and the values are the RubricCriteria objects
  # @returns Rubric

  def update
    association_params = params[:rubric_association] ?
      params[:rubric_association].permit(:use_for_grading, :title, :purpose, :url, :hide_score_total, :hide_points, :hide_outcome_results, :bookmarked) : {}

    @association_object = RubricAssociation.get_association_object(params[:rubric_association])
    params[:rubric][:user] = @current_user if params[:rubric]
    if can_manage_rubrics_or_association_object?(@association_object)
      @association = @context.rubric_associations.where(id: params[:rubric_association_id]).first if params[:rubric_association_id].present?
      @association_object ||= @association.association_object if @association
      association_params[:association_object] = @association_object
      association_params[:update_if_existing] = params[:action] == 'update'
      skip_points_update = !!(params[:skip_updating_points_possible] =~ /true/i)
      association_params[:skip_updating_points_possible] = skip_points_update
      @rubric = @association.rubric if params[:id] && @association && (@association.rubric_id == params[:id].to_i || (@association.rubric && @association.rubric.migration_id == "cloned_from_#{params[:id]}"))
      @rubric ||= @context.rubrics.where(id: params[:id]).first if params[:id].present?
      @association = nil unless @association && @rubric && @association.rubric_id == @rubric.id
      association_params[:id] = @association.id if @association
      # Update the rubric if you can
      # Better specify params[:rubric_association_id] if you want it to update an existing association

      # If this is a brand new rubric OR if the rubric isn't editable,
      # then create a new rubric
      if !@rubric || (@rubric.will_change_with_update?(params[:rubric]) && !@rubric.grants_right?(@current_user, session, :update))
        original_rubric_id = @rubric && @rubric.id
        @rubric = @context.rubrics.build
        @rubric.rubric_id = original_rubric_id
        @rubric.user = @current_user
      end
      if params[:rubric] && (@rubric.grants_right?(@current_user, session, :update) || (@association && @association.grants_right?(@current_user, session, :update))) #authorized_action(@rubric, @current_user, :update)
        @association = @rubric.update_with_association(@current_user, params[:rubric], @context, association_params)
        @rubric = @association.rubric if @association
      end
      json_res = {}
      json_res[:rubric] = @rubric.as_json(:methods => :criteria, :include_root => false, :permissions => {:user => @current_user, :session => session}) if @rubric
      json_res[:rubric_association] = @association.as_json(:include_root => false, :include => [:assessment_requests], :permissions => {:user => @current_user, :session => session}) if @association
      json_res[:rubric_association][:skip_updating_points_possible] = skip_points_update if json_res && json_res[:rubric_association]
      render :json => json_res
    end
  end

  def destroy
    @rubric = RubricAssociation.where(rubric_id: params[:id], context_id: @context, context_type: @context.class.to_s).first.rubric
    if authorized_action(@rubric, @current_user, :delete_associations)
      @rubric.destroy_for(@context)
      render :json => @rubric
    end
  end

  # Internal: Find and format the given context's root outcome group.
  #
  # Returns a JSON outcome object or nil.
  def get_root_outcome
    root_outcome = if @context.respond_to?(:root_outcome_group)
                     @context.root_outcome_group
                   elsif @context.respond_to?(:account)
                     @context.account.root_outcome_group
                   end

    return nil if root_outcome.nil?
    outcome_group_json(root_outcome, @current_user, session)
  end
  protected :get_root_outcome

  private

  def can_manage_rubrics_or_association_object?(object)
    return true if object && (can_update?(object) || can_read?(object) && can_manage_rubrics_context?) ||
                   !object && can_manage_rubrics_context?
    render_unauthorized_action
    false
  end

  def can_update?(object)
    object.grants_right?(@current_user, session, :update)
  end

  def can_read?(object)
    object.grants_right?(@current_user, session, :read)
  end

  def can_manage_rubrics_context?
    @context.grants_right?(@current_user, session, :manage_rubrics)
  end
end
