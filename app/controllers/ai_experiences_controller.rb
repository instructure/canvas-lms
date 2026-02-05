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

  protect_from_forgery except: %i[create update destroy], with: :exception

  before_action :require_context
  before_action :check_ai_experiences_feature_flag
  before_action :require_access_right, only: [:index, :show]
  before_action :require_manage_rights, except: [:index, :show]
  before_action :load_experience, only: %i[show edit update destroy ai_conversations_index ai_conversation_show]

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
    permissions = %i[manage_assignments_add manage_assignments_edit manage_assignments_delete]
    can_manage = @context.grants_any_right?(@current_user, *permissions)

    @experiences = @context.ai_experiences.active
    # Students (non-managers) should only see published experiences
    @experiences = @experiences.where(workflow_state: "published") unless can_manage
    @experiences = @experiences.where(workflow_state: params[:workflow_state]) if params[:workflow_state].present?
    set_active_tab "ai_experiences"
    add_crumb t("#crumbs.ai_experiences", "AI Experiences")
    respond_to do |format|
      format.html do
        @page_title = t("#page_title.ai_experiences", "AI Experiences")
        js_env({ COURSE_ID: @context.id })
        render
      end
      format.json do
        experiences_json = can_manage ? experiences_json_for_teacher : experiences_json_for_student
        render json: {
          experiences: experiences_json,
          can_manage:
        }
      end
    end
  end

  # @API Show an AI experience
  #
  # Retrieve an AI experience by ID
  #
  # @returns AiExperience
  def show
    @ai_experience = @experience
    permissions = %i[manage_assignments_add manage_assignments_edit manage_assignments_delete]
    can_manage = @context.grants_any_right?(@current_user, *permissions)

    # Use the policy to check if user can read this experience
    return unless authorized_action(@ai_experience, @current_user, :read)

    set_active_tab "ai_experiences"
    add_crumb t("#crumbs.ai_experiences", "AI Experiences"), course_ai_experiences_path(@context)
    add_crumb @ai_experience.title
    respond_to do |format|
      format.html do
        @page_title = @ai_experience.title
        js_bundle :ai_experiences_show
        js_env(AI_EXPERIENCE: ai_experience_json(@ai_experience, @current_user, session, can_manage:))
        render html: view_context.content_tag(:div, nil, id: "ai_experiences_show"),
               layout: true
      end
      format.json { render json: ai_experience_json(@experience, @current_user, session, can_manage:) }
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

  # @API List student AI conversations
  #
  # Retrieve the latest AI conversation for each student in the course for this AI experience.
  # Only available to teachers and course managers.
  #
  # @returns [AiConversation]
  def ai_conversations_index
    # Ensure user has manage rights
    permissions = %i[manage_assignments_add manage_assignments_edit manage_assignments_delete]
    unless @context.grants_any_right?(@current_user, *permissions)
      return render_unauthorized_action
    end

    # Get all students in the course with their enrollments preloaded
    students = @context.students.distinct

    # Preload enrollments with sis_pseudonyms to avoid N+1 when calling user_json
    ActiveRecord::Associations.preload(students, enrollments: :sis_pseudonym)

    # Preload user associations for user_json
    user_json_preloads(students, false, accounts: true, pseudonyms: true, profile: true)

    # Build enrollment lookup hash: user_id => enrollment
    enrollments_by_user = students.flat_map(&:enrollments)
                                  .select { |e| e.course_id == @context.id && e.workflow_state != "deleted" }
                                  .group_by(&:user_id)
                                  .transform_values(&:first)

    # Get all latest conversations for all students in one query to avoid N+1
    # Group by user_id and get the most recent conversation for each
    student_ids = students.map(&:id)
    latest_conversations = @experience.ai_conversations
                                      .where(user_id: student_ids)
                                      .where.not(workflow_state: "deleted")
                                      .select("DISTINCT ON (user_id) *")
                                      .order(:user_id, updated_at: :desc)
                                      .to_a

    # Preload users on conversations to avoid N+1
    ActiveRecord::Associations.preload(latest_conversations, :user)

    # Build a hash for quick lookup: user_id => conversation
    conversations_by_user = latest_conversations.index_by(&:user_id)

    # For each student, get their latest conversation for this experience
    conversations = students.map do |student|
      latest_conversation = conversations_by_user[student.id]
      enrollment = enrollments_by_user[student.id]

      if latest_conversation
        # Need to manually build student info to pass enrollment
        student_info = user_json(latest_conversation.user, @current_user, session, ["avatar_url"], @context, nil, [], enrollment)
        json = api_json(latest_conversation, @current_user, session, {})
        json[:student] = student_info
        json
      else
        # Include students without conversations
        # Pass enrollment to user_json to avoid N+1 query for sis_pseudonym
        student_info = user_json(student, @current_user, session, ["avatar_url"], @context, nil, [], enrollment)
        {
          id: nil,
          user_id: student.id.to_s,
          student: {
            id: student_info["id"].to_s,
            name: student_info["name"],
            avatar_url: student_info["avatar_url"]
          },
          has_conversation: false
        }
      end
    end

    render json: { conversations: }
  end

  # @API Show student AI conversation
  #
  # Retrieve a specific student's AI conversation with full message history.
  # Only available to teachers and course managers.
  #
  # @returns AiConversation
  def ai_conversation_show
    # Ensure user has manage rights
    permissions = %i[manage_assignments_add manage_assignments_edit manage_assignments_delete]
    unless @context.grants_any_right?(@current_user, *permissions)
      return render_unauthorized_action
    end

    # Load the conversation and verify it belongs to this experience
    @conversation = AiConversation.find_by(id: params[:conversation_id])

    unless @conversation&.ai_experience == @experience && @conversation.course == @context
      return render json: { error: "Conversation not found" }, status: :not_found
    end

    # Initialize LLM client to fetch message history from the llm-conversation service.
    # We use the student's user context to ensure proper authorization and conversation continuity.
    # The client handles communication with the external LLM service that stores the actual messages.
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

    render json: ai_conversation_json(
      @conversation,
      @current_user,
      session,
      include_student: true,
      messages: messages_and_progress[:messages],
      progress: messages_and_progress[:progress]
    )
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

  def require_access_right
    permissions = %i[manage_assignments_add manage_assignments_edit manage_assignments_delete]
    can_manage = @context.grants_any_right?(@current_user, *permissions)

    # Allow if user can manage OR is enrolled in the course
    return if can_manage || @context.grants_right?(@current_user, :read_as_member)

    render_unauthorized_action
    false
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
    base_params = %i[title description facts learning_objective pedagogical_guidance workflow_state]

    # Only permit context_file_ids if feature flag is enabled
    if @context.feature_enabled?(:ai_experiences_context_file_upload)
      params.expect(ai_experience: [*base_params, { context_file_ids: [] }])
    else
      params.expect(ai_experience: base_params)
    end
  end

  def render_404
    respond_to do |format|
      format.html { render status: :not_found, template: "shared/errors/404_message" }
      format.json { render json: { error: "Resource Not Found" }, status: :not_found }
    end
  end

  def experiences_json_for_teacher
    ai_experiences_json(@experiences, @current_user, session)
  end

  def experiences_json_for_student
    @experiences.map do |experience|
      # Query for the student's latest conversation for this experience
      latest_conversation = experience.ai_conversations
                                      .for_user(@current_user.id)
                                      .where.not(workflow_state: "deleted")
                                      .order(updated_at: :desc)
                                      .first

      # Determine submission status based on conversation state
      submission_status = if latest_conversation.nil?
                            "not_started"
                          elsif latest_conversation.completed?
                            "submitted"
                          else
                            "in_progress"
                          end

      ai_experience_json(experience, @current_user, session, { submission_status: })
    end
  end
end
