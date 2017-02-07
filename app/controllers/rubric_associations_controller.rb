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

class RubricAssociationsController < ApplicationController
  before_filter :require_context
  def create
    update
  end

  def update
    association_params = params[:rubric_association] ?
      params[:rubric_association].permit(:use_for_grading, :title, :purpose, :url, :hide_score_total, :bookmarked, :rubric_id) : {}

    @association = @context.rubric_associations.find(params[:id]) rescue nil
    @association_object = RubricAssociation.get_association_object(params[:rubric_association])
    @association_object = nil unless @association_object && @association_object.try(:context) == @context
    rubric_id = association_params.delete(:rubric_id)
    @rubric = @association ? @association.rubric : Rubric.find(rubric_id)
    # raise "User doesn't have access to this rubric" unless @rubric.grants_right?(@current_user, session, :read)
    if !@association && !authorized_action(@context, @current_user, :manage_rubrics)
      return
    elsif !@association || authorized_action(@association, @current_user, :update)
      if params[:rubric] && @rubric.grants_right?(@current_user, session, :update)
        @rubric.update_criteria(params[:rubric])
      end
      association_params[:association_object] = @association.association_object if @association
      association_params[:association_object] ||= @association_object
      association_params[:id] = @association.id if @association
      @association = RubricAssociation.generate(@current_user, @rubric, @context, association_params)
      json_res = {
        :rubric => @rubric.as_json(:methods => :criteria, :include_root => false, :permissions => {:user => @current_user, :session => session}),
        :rubric_association => @association.as_json(:include_root => false, :include => [:rubric_assessments, :assessment_requests], :methods => :assessor_name, :permissions => {:user => @current_user, :session => session})
      }
      render :json => json_res
    end
  end

  def destroy
    @association = @context.rubric_associations.find(params[:id])
    @rubric = @association.rubric
    if authorized_action(@association, @current_user, :delete)
      @association.destroy
      # If the rubric wasn't created as a general course rubric,
      # and this was the last place it was being used in the course,
      # go ahead and delete the rubric from the course.
      association_count = RubricAssociation.where(:context_id => @context, :context_type => @context.class.to_s, :rubric_id => @rubric).for_grading.count
      if !RubricAssociation.for_purpose('bookmark').where(rubric_id: @rubric).first && association_count == 0
        @rubric.destroy_for(@context)
      end
      render :json => @association
    end
  end
end
