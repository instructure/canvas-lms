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
#           "description": "The AI facts for the experience (optional)",
#           "example": "You are a customer service representative...",
#           "type": "string"
#         },
#         "learning_objective": {
#           "description": "The learning objectives for this experience",
#           "example": "Students will practice active listening and problem-solving",
#           "type": "string"
#         },
#         "pedagogical_guidance": {
#           "description": "The pedagogical guidance for the experience",
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

  protect_from_forgery except: %i[create update destroy continue_conversation], with: :exception

  before_action :require_context
  before_action :check_ai_experiences_feature_flag
  before_action :require_manage_rights
  before_action :load_experience, only: %i[show edit update destroy continue_conversation messages]

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
    set_active_tab "ai_experiences"
    add_crumb t("#crumbs.ai_experiences", "AI Experiences")
    respond_to do |format|
      format.html do
        @page_title = t("#page_title.ai_experiences", "AI Experiences")
        js_env({ COURSE_ID: @context.id })
        render
      end
      format.json { render json: ai_experiences_json(@experiences, @current_user, session) }
    end
  end

  # @API Show an AI experience
  #
  # Retrieve an AI experience by ID
  #
  # @returns AiExperience
  def show
    @ai_experience = @experience
    set_active_tab "ai_experiences"
    add_crumb t("#crumbs.ai_experiences", "AI Experiences"), course_ai_experiences_path(@context)
    add_crumb @ai_experience.title
    respond_to do |format|
      format.html do
        @page_title = @ai_experience.title
        js_bundle :ai_experiences_show
        js_env(AI_EXPERIENCE: ai_experience_json(@ai_experience, @current_user, session))
        render html: view_context.content_tag(:div, nil, id: "ai_experiences_show"),
               layout: true
      end
      format.json { render json: ai_experience_json(@experience, @current_user, session) }
    end
  end

  # @API Show new AI experience form
  #
  # Display the form for creating a new AI experience
  def new
    @experience = @context.ai_experiences.build
    @experience.workflow_state = "unpublished"
    set_active_tab "ai_experiences"
    add_crumb t("#crumbs.ai_experiences", "AI Experiences"), course_ai_experiences_path(@context)
    add_crumb t("#crumbs.new_ai_experience", "New AI Experience")
    @page_title = t("#page_title.new_ai_experience", "New AI Experience")
    js_env({ COURSE_ID: @context.id })
  end

  # @API Show edit AI experience form
  #
  # Display the form for editing an existing AI experience
  def edit
    set_active_tab "ai_experiences"
    add_crumb t("#crumbs.ai_experiences", "AI Experiences"), course_ai_experiences_path(@context)
    add_crumb @experience.title
    @page_title = t("#page_title.edit_ai_experience", "Edit %{title}", title: @experience.title)
    js_env({ COURSE_ID: @context.id, AI_EXPERIENCE_ID: params[:id] })
  end

  # @API Create an AI experience
  #
  # Create a new AI experience for the specified course
  #
  # @argument title [Required, String]
  #   The title of the AI experience.
  # @argument description [Optional, String]
  #   The description of the AI experience.
  # @argument facts [Optional, String]
  #   The AI facts for the experience.
  # @argument learning_objective [Required, String]
  #   The learning objectives for this experience.
  # @argument pedagogical_guidance [Required, String]
  #   The pedagogical guidance for the experience.
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
  # @argument learning_objective [Required, String]
  #   The learning objectives for this experience.
  # @argument pedagogical_guidance [Required, String]
  #   The pedagogical guidance for the experience.
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

  # @API Continue AI conversation
  #
  # Initialize or continue a conversation with the AI experience
  #
  # @argument messages [Optional, Array]
  #   The conversation history. If empty, will return starting messages.
  # @argument conversation_id [Optional, String]
  #   The conversation ID from llm-conversation service. Required for continuing conversations.
  # @argument restart [Optional, Boolean]
  #   If true, marks existing conversation as completed and creates a new one.
  #
  # @returns {Object} Hash with conversation_id and messages array
  def continue_conversation
    # Check if user has an existing active conversation for this experience
    existing_conversation = @experience.ai_conversations
                                       .active
                                       .for_user(@current_user.id)
                                       .first

    # If restart requested, mark existing conversation as completed
    if params[:restart] && existing_conversation
      existing_conversation.complete!
      existing_conversation = nil
    end

    conversation_id = params[:conversation_id] || existing_conversation&.llm_conversation_id

    # If we have a conversation_id but no messages, fetch existing messages
    if conversation_id && params[:messages].blank?
      client = LLMConversationClient.new(
        current_user: @current_user,
        root_account_uuid: @context.root_account.uuid,
        facts: @experience.facts,
        learning_objectives: @experience.learning_objective,
        scenario: @experience.pedagogical_guidance,
        conversation_id:
      )

      messages = client.messages
      return render json: { conversation_id:, messages: }
    end

    service = LLMConversationClient.new(
      current_user: @current_user,
      root_account_uuid: @context.root_account.uuid,
      facts: @experience.facts,
      learning_objectives: @experience.learning_objective,
      scenario: @experience.pedagogical_guidance,
      conversation_id:
    )

    result = if params[:messages].present?
               service.continue_conversation(
                 messages: params[:messages],
                 new_user_message: params[:new_user_message]
               )
             else
               service.starting_messages
             end

    # Save the conversation record if it's new
    if result[:conversation_id] && !existing_conversation
      @experience.ai_conversations.create!(
        llm_conversation_id: result[:conversation_id],
        user: @current_user,
        course: @context,
        root_account: @context.root_account,
        account: @context.account,
        workflow_state: "active"
      )
    end

    render json: result
  rescue LlmConversation::Errors::ConversationError => e
    render json: { error: e.message }, status: :service_unavailable
  end

  # @API Get conversation messages
  #
  # Retrieve messages from an existing conversation in llm-conversation service
  #
  # @argument conversation_id [Required, String]
  #   The conversation ID from llm-conversation service
  #
  # @returns {Object} Hash with conversation_id and messages array
  def messages
    conversation_id = params[:conversation_id]

    unless conversation_id.present?
      return render json: { error: "conversation_id is required" }, status: :bad_request
    end

    client = LLMConversationClient.new(
      current_user: @current_user,
      root_account_uuid: @context.root_account.uuid,
      facts: @experience.facts,
      learning_objectives: @experience.learning_objective,
      scenario: @experience.pedagogical_guidance,
      conversation_id:
    )

    messages = client.messages

    render json: { conversation_id:, messages: }
  rescue LlmConversation::Errors::ConversationError => e
    render json: { error: e.message }, status: :service_unavailable
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
    render_404 unless @experience&.course == @context && !@experience.deleted?
  end

  def require_manage_rights
    permissions = %i[manage_assignments_add manage_assignments_edit manage_assignments_delete]
    unless @context.grants_any_right?(@current_user, *permissions)
      render_unauthorized_action
      false
    end
  end

  def experience_params
    params.expect(ai_experience: %i[title description facts learning_objective pedagogical_guidance workflow_state])
  end

  def render_404
    respond_to do |format|
      format.html { render status: :not_found, template: "shared/errors/404_message" }
      format.json { render json: { error: "Resource Not Found" }, status: :not_found }
    end
  end
end
