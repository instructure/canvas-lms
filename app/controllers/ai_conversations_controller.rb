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
  protect_from_forgery except: %i[create post_message], with: :exception

  before_action :require_context
  before_action :check_ai_experiences_feature_flag
  before_action :load_experience
  before_action :load_conversation, only: %i[post_message destroy]

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
        facts: @experience.facts,
        learning_objectives: @experience.learning_objective,
        scenario: @experience.pedagogical_guidance,
        conversation_id: existing_conversation.llm_conversation_id
      )

      messages = client.messages
      render json: { id: existing_conversation.id, messages: }
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

    # Return only the Canvas conversation ID and messages, not the LLM conversation ID
    render json: { id: conversation_record&.id, messages: result[:messages] }, status: :created
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
      facts: @experience.facts,
      learning_objectives: @experience.learning_objective,
      scenario: @experience.pedagogical_guidance,
      conversation_id: @conversation.llm_conversation_id
    )

    # Get current messages first
    current_messages = client.messages

    # Send the new message
    result = client.continue_conversation(
      messages: current_messages,
      new_user_message: params[:message]
    )

    # Return only the Canvas conversation ID and messages, not the LLM conversation ID
    render json: { id: @conversation.id, messages: result[:messages] }
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

  def load_experience
    @experience = AiExperience.find_by(id: params[:ai_experience_id])
    render_404 unless @experience&.course == @context && !@experience.deleted?
  end

  def load_conversation
    @conversation = @experience.ai_conversations
                               .active
                               .for_user(@current_user.id)
                               .find_by(id: params[:id])
    render_404 unless @conversation
  end

  def render_404
    respond_to do |format|
      format.html { render status: :not_found, template: "shared/errors/404_message" }
      format.json { render json: { error: "Resource Not Found" }, status: :not_found }
    end
  end
end
