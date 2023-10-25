# frozen_string_literal: true

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

# @API Rubrics
# @subtopic RubricAssociations
#
class RubricAssociationsController < ApplicationController
  before_action :require_context

  # @API Create a RubricAssociation
  #
  # Returns the rubric with the given id.
  #
  # @argument rubric_association[rubric_id] [Integer]
  #   The id of the Rubric
  # @argument rubric_association[association_id] [Integer]
  #   The id of the object with which this rubric is associated
  # @argument rubric_association[association_type] ["Assignment"|"Course"|"Account"]
  #   The type of object this rubric is associated with
  # @argument rubric_association[title] [String]
  #   The name of the object this rubric is associated with
  # @argument rubric_association[use_for_grading] [Boolean]
  #   Whether or not the associated rubric is used for grade calculation
  # @argument rubric_association[hide_score_total] [Boolean]
  #   Whether or not the score total is displayed within the rubric.
  #   This option is only available if the rubric is not used for grading.
  # @argument rubric_association[purpose] ["grading"|"bookmark"]
  #   Whether or not the association is for grading (and thus linked to an assignment)
  #   or if it's to indicate the rubric should appear in its context
  # @argument rubric_association[bookmarked] [Boolean]
  #   Whether or not the associated rubric appears in its context
  #
  # @returns RubricAssociation
  def create
    update
  end

  # @API Update a RubricAssociation
  #
  # Returns the rubric with the given id.
  #
  # @argument id [Integer]
  #   The id of the RubricAssociation to update
  # @argument rubric_association[rubric_id] [Integer]
  #   The id of the Rubric
  # @argument rubric_association[association_id] [Integer]
  #   The id of the object with which this rubric is associated
  # @argument rubric_association[association_type] ["Assignment"|"Course"|"Account"]
  #   The type of object this rubric is associated with
  # @argument rubric_association[title] [String]
  #   The name of the object this rubric is associated with
  # @argument rubric_association[use_for_grading] [Boolean]
  #   Whether or not the associated rubric is used for grade calculation
  # @argument rubric_association[hide_score_total] [Boolean]
  #   Whether or not the score total is displayed within the rubric.
  #   This option is only available if the rubric is not used for grading.
  # @argument rubric_association[purpose] ["grading"|"bookmark"]
  #   Whether or not the association is for grading (and thus linked to an assignment)
  #   or if it's to indicate the rubric should appear in its context
  # @argument rubric_association[bookmarked] [Boolean]
  #   Whether or not the associated rubric appears in its context
  #
  # @returns RubricAssociation
  def update
    association_params = if params[:rubric_association]
                           params[:rubric_association].permit(:use_for_grading, :title, :purpose, :url, :hide_score_total, :bookmarked, :rubric_id)
                         else
                           {}
                         end

    @association = @context.rubric_associations.find(params[:id]) rescue nil
    @association_object = RubricAssociation.get_association_object(params[:rubric_association])
    @association_object = nil unless @association_object && @association_object.try(:context) == @context
    rubric_id = association_params.delete(:rubric_id)
    @rubric = @association ? @association.rubric : Rubric.find(rubric_id)
    # raise "User doesn't have access to this rubric" unless @rubric.grants_right?(@current_user, session, :read)
    return unless can_manage_rubrics_or_association_object?(@association, @association_object)
    return unless can_update_association?(@association)

    # create a new rubric if associating in a different course
    rubric_context = @rubric.context
    from_different_shard = rubric_context.shard != @context.shard
    if rubric_context != @context && rubric_context.is_a?(Course)
      @rubric = @rubric.dup
      @rubric.rubric_id = rubric_id
      @rubric.rubric_id = nil if from_different_shard
      @rubric.update_criteria(params[:rubric]) if params[:rubric]
      @rubric.user = @current_user
      @rubric.context = @context
      @rubric.update_mastery_scales(false)
      @rubric.shard = @context.shard if from_different_shard
      @rubric.save!
    elsif params[:rubric] && @rubric.grants_right?(@current_user, session, :update)
      @rubric.update_criteria(params[:rubric])
    end

    association_params[:association_object] = @association.association_object if @association
    association_params[:association_object] ||= @association_object
    association_params[:id] = @association.id if @association
    @association = RubricAssociation.generate(@current_user, @rubric, @context, association_params)
    json_res = {
      rubric: @rubric.as_json(methods: :criteria, include_root: false, permissions: { user: @current_user,
                                                                                      session: }),
      rubric_association: @association.as_json(include_root: false,
                                               include: %i[rubric_assessments assessment_requests],
                                               permissions: { user: @current_user, session: })
    }
    render json: json_res
  end

  # @API Delete a RubricAssociation
  #
  # Delete the RubricAssociation with the given ID
  #
  # @returns RubricAssociation
  def destroy
    @association = @context.rubric_associations.find(params[:id])
    @rubric = @association.rubric
    if authorized_action(@association, @current_user, :delete)
      @association.updating_user = @current_user
      @association.destroy
      # If the rubric wasn't created as a general course rubric,
      # and this was the last place it was being used in the course,
      # go ahead and delete the rubric from the course.
      association_count = RubricAssociation.active.where(context_id: @context, context_type: @context.class.to_s, rubric_id: @rubric).for_grading.count
      if !RubricAssociation.active.for_purpose("bookmark").where(rubric_id: @rubric).first && association_count == 0
        @rubric.destroy_for(@context, current_user: @current_user)
      end
      render json: @association
    end
  end

  private

  def can_manage_rubrics_or_association_object?(association, association_object)
    return true if association ||
                   @context.grants_right?(@current_user, session, :manage_rubrics) ||
                   association_object&.grants_right?(@current_user, session, :update)

    render_unauthorized_action
    false
  end

  def can_update_association?(association)
    !association || authorized_action(association, @current_user, :update)
  end
end
