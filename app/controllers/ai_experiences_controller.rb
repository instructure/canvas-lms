# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

# @API AI Experiences
# API for creating, accessing and updating AI Experiences. AI Experiences are
# used to create interactive AI-powered learning scenarios within courses.
#
# @model AiExperience
#     {
#       "id": "AiExperience",
#       "description": "An AI Experience for interactive learning",
#       "properties": {
#         "id": {
#           "description": "The ID of the AI experience",
#           "example": 234,
#           "type": "integer"
#         },
#         "title": {
#           "description": "The title for the AI experience",
#           "example": "Customer Service Simulation",
#           "type": "string"
#         },
#         "description": {
#           "description": "The description of the AI experience",
#           "example": "Practice customer service skills in a simulated environment",
#           "type": "string"
#         },
#         "facts": {
#           "description": "The AI facts for the experience",
#           "example": "You are a customer service representative...",
#           "type": "string"
#         },
#         "learning_objective": {
#           "description": "The learning objectives for this experience",
#           "example": "Students will practice active listening and problem-solving",
#           "type": "string"
#         },
#         "scenario": {
#           "description": "The scenario description for the experience",
#           "example": "A customer is calling about a billing issue",
#           "type": "string"
#         },
#         "workflow_state": {
#           "description": "The current published state of the AI experience",
#           "example": "published",
#           "type": "string"
#         },
#         "course_id": {
#           "description": "The course this experience belongs to",
#           "example": 1578941,
#           "type": "integer"
#         }
#       }
#     }

class AiExperiencesController < ApplicationController
  include Api::V1::AiExperience

  protect_from_forgery except: %i[create update destroy], with: :exception

  before_action :require_context
  before_action :check_ai_experiences_feature_flag
  before_action :load_experience, only: %i[show edit update destroy]
  before_action :require_read_rights, only: %i[index show]
  before_action :require_manage_rights, only: %i[new create edit update destroy]

  # @API List AI experiences
  #
  # Retrieve the paginated list of AI experiences for a course
  #
  # @argument workflow_state [String]
  #   Only return experiences with the specified workflow state.
  #   Allowed values: published, unpublished, deleted
  #
  # @returns [AiExperience]
  def index
    @experiences = @context.ai_experiences.active
    @experiences = @experiences.where(workflow_state: params[:workflow_state]) if params[:workflow_state].present?
    respond_to do |format|
      format.html { render }
      format.json { render json: ai_experiences_json(@experiences, @current_user, session) }
    end
  end

  # @API Show an AI experience
  #
  # Retrieve an AI experience by ID
  #
  # @returns AiExperience
  def show
    # For now this endpoint is not accesible for the MTP
    render_404
  end

  # @API Show new AI experience form
  #
  # Display the form for creating a new AI experience
  def new
    # For now this endpoint is not accessible for the MTP
    render_404
  end

  # @API Show edit AI experience form
  #
  # Display the form for editing an existing AI experience
  def edit
    # For now this endpoint is not accessible for the MTP
    render_404
  end

  # @API Create an AI experience
  #
  # Create a new AI experience for the specified course
  #
  # @argument title [Required, String]
  #   The title of the AI experience.
  # @argument description [Optional, String]
  #   The description of the AI experience.
  # @argument facts [Required, String]
  #   The AI facts for the experience.
  # @argument learning_objective [Optional, String]
  #   The learning objectives for this experience.
  # @argument scenario [Optional, String]
  #   The scenario description for the experience.
  # @argument workflow_state [Optional, String]
  #   The initial state of the experience. Defaults to 'unpublished'.
  #   Allowed values: published, unpublished
  #
  # @returns AiExperience
  def create
    @experience = @context.ai_experiences.build(experience_params)
    @experience.root_account = @context.root_account
    @experience.account = @context.account

    if @experience.save
      respond_to do |format|
        format.json { render json: ai_experience_json(@experience, @current_user, session), status: :created }
      end
    else
      respond_to do |format|
        format.json { render json: @experience.errors, status: :bad_request }
      end
    end
  end

  # @API Update an AI experience
  #
  # Update an existing AI experience
  #
  # @argument title [Optional, String]
  #   The title of the AI experience.
  # @argument description [Optional, String]
  #   The description of the AI experience.
  # @argument facts [Optional, String]
  #   The AI facts for the experience.
  # @argument learning_objective [Optional, String]
  #   The learning objectives for this experience.
  # @argument scenario [Optional, String]
  #   The scenario description for the experience.
  # @argument workflow_state [Optional, String]
  #   The state of the experience.
  #   Allowed values: published, unpublished
  #
  # @returns AiExperience
  def update
    if @experience.update(experience_params)
      respond_to do |format|
        format.json { render json: ai_experience_json(@experience, @current_user, session), status: :ok }
      end
    else
      respond_to do |format|
        format.json { render json: @experience.errors, status: :bad_request }
      end
    end
  end

  # @API Delete an AI experience
  #
  # Delete an AI experience (soft delete - marks as deleted)
  #
  # @returns AiExperience
  def destroy
    if @experience.delete
      respond_to do |format|
        format.json { render json: ai_experience_json(@experience, @current_user, session), status: :ok }
      end
    else
      respond_to do |format|
        format.json { render json: @experience.errors, status: :bad_request }
      end
    end
  end

  private

  def check_ai_experiences_feature_flag
    unless @context&.feature_enabled?(:ai_experiences)
      render_404
      false
    end
  end

  def load_experience
    @experience = AiExperience.find_by(id: params[:id])
    return render_404 unless @experience&.course == @context && !@experience.deleted?

    nil unless authorized_action(@context, @current_user, :read)
  end

  def require_read_rights
    render_unauthorized_action unless authorized_action(@context, @current_user, :read)
  end

  def require_manage_rights
    permissions = %i[manage_assignments_add manage_assignments_edit manage_assignments_delete]
    unless @context.grants_any_right?(@current_user, *permissions)
      render_unauthorized_action
      false
    end
  end

  def experience_params
    params.permit(:title, :description, :facts, :learning_objective, :scenario, :workflow_state)
  end

  def render_404
    respond_to do |format|
      format.html { render file: Rails.public_path.join("404.html").to_s, status: :not_found, layout: false }
      format.json { render json: { error: "Resource Not Found" }, status: :not_found }
    end
  end
end
