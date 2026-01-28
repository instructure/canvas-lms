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

# @API AI Conversations
# API for managing conversations with AI Experiences.
class AiConversationsController < ApplicationController
  include Api::V1::AiExperience

  protect_from_forgery except: %i[create post_message], with: :exception

  before_action :require_context
  before_action :check_ai_experiences_feature_flag
  before_action :require_access_right
  before_action :load_experience
  before_action :load_conversation, only: %i[post_message destroy show]

  # Display the page for teachers to view all student AI conversations
  # Returns HTML for teachers, JSON for students (their active conversation)
  #
  # @returns HTML page or JSON
  def index
    # Teacher view - show all student conversations
    permissions = %i[manage_assignments_add manage_assignments_edit manage_assignments_delete]
    unless @context.grants_any_right?(@current_user, *permissions)
      return render_unauthorized_action
    end

    set_active_tab "ai_experiences"
    add_crumb t("#crumbs.ai_experiences", "AI Experiences"), course_ai_experiences_path(@context)
    add_crumb @experience.title, course_ai_experience_path(@context, @experience)
    add_crumb t("#crumbs.ai_conversations", "AI Conversations")

    @page_title = t("#page_title.ai_conversations", "%{title} - AI Conversations", title: @experience.title)
    js_bundle :ai_experiences_ai_conversations
    js_env(
      AI_EXPERIENCE: ai_experience_json(@experience, @current_user, session, can_manage: true),
      COURSE_ID: @context.id
    )

    render html: view_context.content_tag(:div, nil, id: "ai_experiences_ai_conversations"), layout: true
  end

  # @API Show conversation
  #
  # Get a specific conversation by ID (for teachers viewing student conversations)
  #
  # @returns {Object} Hash with conversation details including messages
  def show
    # Teachers can view any student's conversation
    permissions = %i[manage_assignments_add manage_assignments_edit manage_assignments_delete]
    unless @context.grants_any_right?(@current_user, *permissions)
      return render_unauthorized_action
    end

    client = LLMConversationClient.new(
      current_user: @conversation.user,
      root_account_uuid: @context.root_account.uuid,
      conversation_context_id: @experience.llm_conversation_context_id,
      facts: @experience.facts,
      learning_objectives: @experience.learning_objective,
      scenario: @experience.pedagogical_guidance,
      conversation_id: @conversation.llm_conversation_id
    )

    messages_and_progress = client.messages_with_conversation_progress
    render json: {
      id: @conversation.id,
      user_id: @conversation.user_id.to_s,
      llm_conversation_id: @conversation.llm_conversation_id,
      workflow_state: @conversation.workflow_state,
      created_at: @conversation.created_at,
      updated_at: @conversation.updated_at,
      messages: messages_and_progress[:messages],
      progress: messages_and_progress[:progress]
    }
  rescue LlmConversation::Errors::ConversationError => e
    render json: { error: e.message }, status: :service_unavailable
  end

  # @API Get active conversation
  #
  # Get the active conversation for the current user and AI experience
  #
  # @returns {Object} Hash with id and messages array, or empty object if no active conversation
  def active_conversation
    existing_conversation = @experience.ai_conversations
                                       .active
                                       .for_user(@current_user.id)
                                       .first

    if existing_conversation
      client = LLMConversationClient.new(
        current_user: @current_user,
        root_account_uuid: @context.root_account.uuid,
        conversation_context_id: @experience.llm_conversation_context_id,
        # Fallback to inline variables if no context exists (for older records)
        facts: @experience.facts,
        learning_objectives: @experience.learning_objective,
        scenario: @experience.pedagogical_guidance,
        conversation_id: existing_conversation.llm_conversation_id
      )

      messages_and_progress = client.messages_with_conversation_progress
      render json: { id: existing_conversation.id, messages: messages_and_progress[:messages], progress: messages_and_progress[:progress] }
    else
      render json: {}
    end
  rescue LlmConversation::Errors::ConversationError => e
    render json: { error: e.message }, status: :service_unavailable
  end

  # @API Create AI conversation
  #
  # Initialize a new conversation with the AI experience
  #
  # @returns {Object} Hash with conversation_id and initial messages array
  def create
    # Check if user has an existing active conversation for this experience
    existing_conversation = @experience.ai_conversations
                                       .active
                                       .for_user(@current_user.id)
                                       .first

    # If active conversation exists, complete it before creating a new one
    existing_conversation&.complete!

    client = LLMConversationClient.new(
      current_user: @current_user,
      root_account_uuid: @context.root_account.uuid,
      conversation_context_id: @experience.llm_conversation_context_id,
      # Fallback to inline variables if no context exists (for older records)
      facts: @experience.facts,
      learning_objectives: @experience.learning_objective,
      scenario: @experience.pedagogical_guidance
    )

    result = client.starting_messages

    # Save the conversation record
    conversation_record = nil
    if result[:conversation_id]
      conversation_record = @experience.ai_conversations.create!(
        llm_conversation_id: result[:conversation_id],
        user: @current_user,
        course: @context,
        root_account: @context.root_account,
        account: @context.account,
        workflow_state: "active"
      )
    end

    # Return only the Canvas conversation ID, messages, and progress
    render json: { id: conversation_record&.id, messages: result[:messages], progress: result[:progress] }, status: :created
  rescue LlmConversation::Errors::ConversationError => e
    render json: { error: e.message }, status: :service_unavailable
  end

  # @API Post message to conversation
  #
  # Send a message to an existing conversation and get the AI response
  #
  # @argument message [Required, String]
  #   The user's message to send to the AI
  #
  # @returns {Object} Hash with id and updated messages array
  def post_message
    unless params[:message].present?
      return render json: { error: "message is required" }, status: :bad_request
    end

    client = LLMConversationClient.new(
      current_user: @current_user,
      root_account_uuid: @context.root_account.uuid,
      conversation_context_id: @experience.llm_conversation_context_id,
      # Fallback to inline variables if no context exists (for older records)
      facts: @experience.facts,
      learning_objectives: @experience.learning_objective,
      scenario: @experience.pedagogical_guidance,
      conversation_id: @conversation.llm_conversation_id
    )

    # Get current messages first
    messages_data = client.messages
    current_messages = messages_data[:messages]

    # Send the new message
    result = client.continue_conversation(
      messages: current_messages,
      new_user_message: params[:message]
    )

    # Return only the Canvas conversation ID, messages, and progress
    render json: { id: @conversation.id, messages: result[:messages], progress: result[:progress] }
  rescue LlmConversation::Errors::ConversationError => e
    render json: { error: e.message }, status: :service_unavailable
  end

  # @API Delete AI conversation
  #
  # Mark a conversation as completed/deleted
  #
  # @returns {Object} Success message
  def destroy
    @conversation.complete!
    render json: { message: "Conversation completed successfully" }
  end

  private

  def check_ai_experiences_feature_flag
    unless @context&.feature_enabled?(:ai_experiences)
      render_404
      false
    end
  end

  def require_access_right
    permissions = %i[manage_assignments_add manage_assignments_edit manage_assignments_delete]
    can_manage = @context.grants_any_right?(@current_user, *permissions)

    # Allow if user can manage OR is enrolled in the course
    return if can_manage || @context.grants_right?(@current_user, :read_as_member)

    render_unauthorized_action
    false
  end

  def load_experience
    @experience = AiExperience.find_by(id: params[:ai_experience_id])
    render_404 unless @experience&.course == @context && !@experience.deleted?
  end

  def load_conversation
    # For teachers, allow loading any conversation; for students, only their own
    permissions = %i[manage_assignments_add manage_assignments_edit manage_assignments_delete]
    @conversation = if @context.grants_any_right?(@current_user, *permissions)
                      # Teachers can view any conversation
                      @experience.ai_conversations.find_by(id: params[:id])
                    else
                      # Students can only view their own active conversations
                      @experience.ai_conversations
                                 .active
                                 .for_user(@current_user.id)
                                 .find_by(id: params[:id])
                    end
    render_404 unless @conversation
  end

  def render_404
    respond_to do |format|
      format.html { render status: :not_found, template: "shared/errors/404_message" }
      format.json { render json: { error: "Resource Not Found" }, status: :not_found }
    end
  end
end
