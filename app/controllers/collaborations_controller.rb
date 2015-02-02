#
# Copyright (C) 2011-2012 Instructure, Inc.
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

# @API Collaborations
# API for accessing course and group collaboration information.
#
# @model Collaborator
#     {
#       "id": "Collaborator",
#       "description": "",
#       "required": ["id"],
#       "properties": {
#         "id": {
#           "description": "The unique user or group identifier for the collaborator.",
#           "example": 12345,
#           "type": "integer"
#         },
#         "type": {
#           "description": "The type of collaborator (e.g. 'user' or 'group').",
#           "example": "user",
#           "type": "string",
#           "allowableValues": {
#             "values": [
#               "user",
#               "group"
#             ]
#           }
#         },
#         "name": {
#           "description": "The name of the collaborator.",
#           "example": "Don Draper",
#           "type": "string"
#         }
#       }
#     }
#
class CollaborationsController < ApplicationController
  before_filter :require_context, :except => [:members]
  before_filter :require_collaboration_and_context, :only => [:members]
  before_filter :require_collaborations_configured
  before_filter :reject_student_view_student

  before_filter { |c| c.active_tab = "collaborations" }

  include Api::V1::Collaborator

  def index
    return unless authorized_action(@context, @current_user, :read) &&
      tab_enabled?(@context.class::TAB_COLLABORATIONS)

    add_crumb(t('#crumbs.collaborations', "Collaborations"), polymorphic_path([@context, :collaborations]))

    @collaborations = @context.collaborations.active
    log_asset_access("collaborations:#{@context.asset_string}", "collaborations", "other")

    @google_docs_authorized = google_docs_connection.verify_access_token rescue false
    js_env :TITLE_MAX_LEN => Collaboration::TITLE_MAX_LENGTH,
           :collaboration_types => Collaboration.collaboration_types
  end

  def show
    @collaboration = @context.collaborations.find(params[:id])
    if authorized_action(@collaboration, @current_user, :read)
      @collaboration.touch
      if @collaboration.valid_user?(@current_user)
        @collaboration.authorize_user(@current_user)
        log_asset_access(@collaboration, "collaborations", "other", 'participate')
        redirect_to @collaboration.url
      elsif @collaboration.is_a?(GoogleDocsCollaboration)
        redirect_to oauth_url(:service => :google_docs, :return_to => request.url)
      else
        flash[:error] = t 'errors.cannot_load_collaboration', "Cannot load collaboration"
        redirect_to named_context_url(@context, :context_collaborations_url)
      end
    end
  end

  def create
    return unless authorized_action(@context.collaborations.build, @current_user, :create)
    users     = User.where(:id => Array(params[:user])).all
    group_ids = Array(params[:group])
    params[:collaboration][:user] = @current_user
    @collaboration = Collaboration.typed_collaboration_instance(params[:collaboration].delete(:collaboration_type))
    @collaboration.context = @context
    @collaboration.attributes = params[:collaboration]
    respond_to do |format|
      if @collaboration.save
        # After saved, update the members
        @collaboration.update_members(users, group_ids)
        format.html { redirect_to @collaboration.url }
        format.json { render :json => @collaboration.as_json(:methods => [:collaborator_ids], :permissions => {:user => @current_user, :session => session}) }
      else
        flash[:error] = t 'errors.create_failed', "Collaboration creation failed"
        format.html { redirect_to named_context_url(@context, :context_collaborations_url) }
        format.json { render :json => @collaboration.errors, :status => :bad_request }
      end
    end
  end

  def update
    @collaboration = @context.collaborations.find(params[:id])
    return unless authorized_action(@collaboration, @current_user, :update)
    users     = User.where(:id => Array(params[:user])).all
    group_ids = Array(params[:group])
    params[:collaboration].delete :collaboration_type
    @collaboration.attributes = params[:collaboration]
    @collaboration.update_members(users, group_ids)
    respond_to do |format|
      if @collaboration.save
        format.html { redirect_to named_context_url(@context, :context_collaborations_url) }
        format.json { render :json => @collaboration.as_json(:methods => [:collaborator_ids], :permissions => {:user => @current_user, :session => session}) }
      else
        flash[:error] = t 'errors.update_failed', "Collaboration update failed"
        format.html { redirect_to named_context_url(@context, :context_collaborations_url) }
        format.json { render :json => @collaboration.errors, :status => :bad_request }
      end
    end
  end

  def destroy
    @collaboration = @context.collaborations.find(params[:id])
    if authorized_action(@collaboration, @current_user, :delete)
      @collaboration.delete_document if params[:delete_doc]
      @collaboration.destroy
      respond_to do |format|
        format.html { redirect_to named_context_url(@context, :collaborations_url) }
        format.json { render :json => @collaboration }
      end
    end
  end

  # @API List members of a collaboration.
  #
  # List the collaborators of a given collaboration
  #
  # @example_request
  #
  #   curl https://<canvas>/api/v1/courses/1/collaborations/1/members
  #
  # @returns [Collaborator]
  def members
    return unless authorized_action(@collaboration, @current_user, :read)
    collaborators = @collaboration.collaborators.includes(:group, :user)
    collaborators = Api.paginate(collaborators,
                                 self,
                                 api_v1_collaboration_members_url)

    render :json => collaborators.map { |c| collaborator_json(c, @current_user, session) }
  end

  private
  def require_collaboration_and_context
    @collaboration = if @context.present?
                       @context.collaborations.find(params[:id])
                     else
                       Collaboration.find(params[:id])
                     end
    @context = @collaboration.context
  end

  def require_collaborations_configured
    unless Collaboration.any_collaborations_configured?
      flash[:error] = t 'errors.not_enabled', "Collaborations have not been enabled for this Canvas site"
      redirect_to named_context_url(@context, :context_url)
      return false
    end
  end
end

