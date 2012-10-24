#
# Copyright (C) 2012 Instructure, Inc.
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

# @API Outcome Groups
#
# API for accessing learning outcome group information.
class OutcomeGroupsApiController < ApplicationController
  include Api::V1::Outcome

  before_filter :get_context, :except => :global_redirect
  before_filter :require_context, :only => :context_redirect

  # @API Redirect for global outcomes
  # Convenience redirect to find the root outcome group for global outcomes.
  def redirect
    if can_read_outcomes
      @outcome_group = @context ?
        @context.root_outcome_group :
        LearningOutcomeGroup.global_root_outcome_group
      redirect_to polymorphic_path [:api_v1, @context || :global, :outcome_group], :id => @outcome_group.id
    end
  end

  # @API Retrieve an outcome group's details.
  def show
    if can_read_outcomes
      @outcome_group = context_outcome_groups.find(params[:id])
      render :json => outcome_group_json(@outcome_group, @current_user, session)
    end
  end

  # @API Update an outcome group.
  def update
    if can_manage_outcomes
      @outcome_group = context_outcome_groups.find(params[:id])
      if @outcome_group.learning_outcome_group_id.nil?
        render :json => 'error'.to_json, :status => :bad_request
        return
      end
      @outcome_group.update_attributes(params.slice(:title, :description))
      if params[:parent_outcome_group_id] && params[:parent_outcome_group_id] != @outcome_group.learning_outcome_group_id
        new_parent = context_outcome_groups.find(params[:parent_outcome_group_id])
        unless new_parent.adopt_outcome_group(@outcome_group)
          render :json => 'error'.to_json, :status => :bad_request
          return
        end
      end
      if @outcome_group.save
        render :json => outcome_group_json(@outcome_group, @current_user, session)
      else
        render :json => @outcome_group.errors, :status => :bad_request
      end
    end
  end

  # @API Delete an outcome group.
  def destroy
    if can_manage_outcomes
      @outcome_group = context_outcome_groups.find(params[:id])
      if @outcome_group.learning_outcome_group_id.nil?
        render :json => 'error'.to_json, :status => :bad_request
        return
      end
      begin
        @outcome_group.destroy
        render :json => outcome_group_json(@outcome_group, @current_user, session)
      rescue ActiveRecord::RecordNotSaved
        render :json => 'error'.to_json, :status => :bad_request
      end
    end
  end

  # @API List the outcomes in a group.
  def outcomes
    if can_read_outcomes
      @outcome_group = context_outcome_groups.find(params[:id])

      # get and paginate links from group
      link_scope = @outcome_group.child_outcome_links.active.order_by_outcome_title
      url = polymorphic_url [:api_v1, @context, :outcome_group_outcomes], :id => @outcome_group.id
      @links = Api.paginate(link_scope, self, url)

      # pre-populate the links' groups and contexts to prevent
      # extraneous loads
      @links.each do |link|
        link.associated_asset = @outcome_group
        link.context = @outcome_group.context
      end

      # preload the links' outcomes' contexts.
      ContentTag.send(:preload_associations, @links, :learning_outcome_content => :context)

      # render to json and serve
      render :json => @links.map{ |link| outcome_link_json(link, @current_user, session) }
    end
  end

  # @API Link an outcome into a group.
  def link
    if can_manage_outcomes
      @outcome_group = context_outcome_groups.find(params[:id])
      if params[:outcome_id]
        @outcome = context_available_outcome(params[:outcome_id])
        unless @outcome
          render :json => 'error'.to_json, :status => :bad_request
          return
        end
      else
        @outcome = context_create_outcome(params.slice(:title, :description, :ratings, :mastery_points))
        unless @outcome.valid?
          render :json => @outcome.errors, :status => :bad_request
          return
        end
      end
      @outcome_link = @outcome_group.add_outcome(@outcome)
      render :json => outcome_link_json(@outcome_link, @current_user, session)
    end
  end

  # @API Unlink an outcome link in a group.
  def unlink
    if can_manage_outcomes
      @outcome_group = context_outcome_groups.find(params[:id])
      @outcome_link = @outcome_group.child_outcome_links.active.find_by_content_id(params[:outcome_id])
      raise ActiveRecord::RecordNotFound unless @outcome_link
      begin
        @outcome_link.destroy
        render :json => outcome_link_json(@outcome_link, @current_user, session)
      rescue ActiveRecord::RecordNotSaved
        render :json => 'error'.to_json, :status => :bad_request
      end
    end
  end

  # @API List the outcomes in a group.
  def subgroups
    if can_read_outcomes
      @outcome_group = context_outcome_groups.find(params[:id])

      # get and paginate subgroups from group
      subgroup_scope = @outcome_group.child_outcome_groups.active.order_by_title
      url = polymorphic_url [:api_v1, @context, :outcome_group_subgroups], :id => @outcome_group.id
      @subgroups = Api.paginate(subgroup_scope, self, url)

      # pre-populate the subgroups' parent groups to prevent extraneous
      # loads
      @subgroups.each{ |group| group.context = @outcome_group.context }

      # render to json and serve
      render :json => @subgroups.map{ |group| outcome_group_json(group, @current_user, session, :abbrev) }
    end
  end

  # @API Create a new subgroup of a group.
  def create
    if can_manage_outcomes
      @outcome_group = context_outcome_groups.find(params[:id])
      @child_outcome_group = @outcome_group.child_outcome_groups.build(params.slice(:title, :description))
      if @child_outcome_group.save
        render :json => outcome_group_json(@child_outcome_group, @current_user, session)
      else
        render :json => 'error'.to_json, :status => :bad_request
      end
    end
  end

  # @API Import an existing non-root outcome group into a group.
  def import
    if can_manage_outcomes
      @outcome_group = context_outcome_groups.find(params[:id])

      # source has to exist
      @source_outcome_group = LearningOutcomeGroup.active.find_by_id(params[:source_outcome_group_id])
      unless @source_outcome_group
        render :json => 'error'.to_json, :status => :bad_request
        return
      end

      # source has to be global, in same context, or in an associated
      # account
      source_context = @source_outcome_group.context
      unless !source_context || source_context == @context || @context.associated_accounts.include?(source_context)
        render :json => 'error'.to_json, :status => :bad_request
        return
      end

      # source can't be a root group
      unless @source_outcome_group.learning_outcome_group_id
        render :json => 'error'.to_json, :status => :bad_request
        return
      end

      # import the validated source
      @child_outcome_group = @outcome_group.add_outcome_group(@source_outcome_group)
      render :json => outcome_group_json(@child_outcome_group, @current_user, session)
    end
  end

  protected

  def can_read_outcomes
    if @context
      authorized_action(@context, @current_user, :manage_outcomes)
    else
      # anyone (that's logged in) can read global outcomes
      true
    end
  end

  def can_manage_outcomes
    if @context
      authorized_action(@context, @current_user, :manage_outcomes)
    else
      authorized_action(Account.site_admin, @current_user, :manage_global_outcomes)
    end
  end

  # get the active outcome groups in the context/global
  def context_outcome_groups
    LearningOutcomeGroup.for_context(@context).active
  end

  # verify the outcome is eligible to be linked into the context,
  # returning the outcome if so
  def context_available_outcome(outcome_id)
    if @context
      @context.available_outcome(outcome_id, :allow_global => true)
    else
      LearningOutcome.global.find_by_id(outcome_id)
    end
  end

  def context_create_outcome(data)
    scope = @context ? @context.created_learning_outcomes : LearningOutcome.global
    outcome = scope.build(data.slice(:title, :description))
    if data[:ratings]
      outcome.rubric_criterion = data.slice(:ratings, :mastery_points)
    end
    outcome.save
    outcome
  end
end
