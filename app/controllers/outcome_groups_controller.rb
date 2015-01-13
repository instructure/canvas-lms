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

class OutcomeGroupsController < ApplicationController
  before_filter :require_context

  def create
    if authorized_action(@context, @current_user, :manage_outcomes)
      parent_id = params[:learning_outcome_group].delete(:learning_outcome_group_id)
      parent_outcome_group = parent_id ? @context.learning_outcome_groups.find(parent_id) : @context.root_outcome_group
      @outcome_group = parent_outcome_group.child_outcome_groups.build(params[:learning_outcome_group].merge(:context => @context))
      respond_to do |format|
        if @outcome_group.save
          format.json { render :json => @outcome_group }
        else
          format.json { render :json => @outcome_group.errors, :status => :bad_request }
        end
      end
    end
  end

  def import
    if authorized_action(@context, @current_user, :manage_outcomes)
      data = JSON.parse(params[:file].read).with_indifferent_access rescue nil
      if data && data[:category] && data[:title] && data[:description] && data[:outcomes]
        params = {}
        group = @context.learning_outcome_groups.create(params)
        data[:outcomes].each do |outcome_hash|
          params = {}
          outcome_hash = outcome_hash.with_indifferent_access
          outcome = group.learning_outcomes.create(params)
        end
        render :json => group.as_json(:include => :learning_outcomes),
               :as_text => true
      else
        render :json => {:errors => {:base => t(:invalid_file, "Invalid outcome group file")}},
               :status => :bad_request,
               :as_text => true
      end
    end
  end

  def update
    if authorized_action(@context, @current_user, :manage_outcomes)
      @outcome_group = @context.learning_outcome_groups.active.find(params[:id])
      respond_to do |format|
        parent_id = params[:learning_outcome_group].delete(:learning_outcome_group_id)
        @outcome_group.attributes = params[:learning_outcome_group]
        @outcome_group.learning_outcome_group = @context.learning_outcome_groups.find(parent_id) if parent_id
        if @outcome_group.save
          format.json { render :json => @outcome_group }
        else
          format.json { render :json => @outcome_group.errors, :status => :bad_request }
        end
      end
    end
  end

  def destroy
    if authorized_action(@context, @current_user, :manage_outcomes)
      @outcome_group = @context.learning_outcome_groups.active.find(params[:id])
      @outcome_group.skip_tag_touch = true
      @outcome_group.destroy
      @context.touch
      render :json => @outcome_group
    end
  end

  def reorder
    if authorized_action(@context, @current_user, :manage_outcomes)
      @outcome_group = @context.learning_outcome_groups.active.find(params[:outcome_group_id])
      @asset_strings = @outcome_group.reorder_content(params[:ordering])
      render :json => @asset_strings
    end
  end
end
