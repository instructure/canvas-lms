# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

# @API Study Assist
# Student-facing AI-powered study tools (Summarize, Quiz me, Flashcards)
# backed by Cedar. Scoped to a single course; requires a student enrollment.
class StudyAssistController < ApplicationController
  MAX_PROMPT_BYTES = 2.kilobytes

  before_action :require_context
  before_action :require_study_assist_enabled
  before_action :require_student_access
  before_action :require_cedar_enabled

  # @API Request a study assist response
  #
  # @argument prompt [String] Short prompt (e.g. "Summarize"). Blank returns chips.
  # @argument state [Hash] Content state with courseID, and one of pageID or fileID.
  # @argument regenerate [Boolean] If true, bypasses the LLM response cache.
  #
  # @returns AssistResponse
  def create
    request_body = assist_request_params
    return unless valid_request?(request_body)

    response =
      GuardRail.activate(:secondary) do
        StudyAssist::Service.call(
          course: @context,
          user: @current_user,
          prompt: request_body[:prompt],
          state: request_body[:state],
          locale: I18n.locale.to_s,
          regenerate: value_to_boolean(request_body[:regenerate])
        )
      end

    record_metric(tool_tag(request_body[:prompt]), "success")
    render json: response
  rescue StudyAssist::InvalidPrompt
    record_metric("unknown", "unsupported")
    render json: { error: t("Study tools aren't available for this prompt.") }, status: :unprocessable_content
  rescue StudyAssist::ToolDisabled
    record_metric(tool_tag(request_body[:prompt]), "unsupported")
    render json: { error: t("This study tool isn't currently available.") }, status: :forbidden
  rescue StudyAssist::UnsupportedContentType
    record_metric(tool_tag(request_body[:prompt]), "unsupported")
    render json: { error: t("Study tools aren't available for this file type.") }, status: :unprocessable_content
  rescue StudyAssist::ContentUnavailable => e
    record_metric(tool_tag(request_body[:prompt]), "content_unavailable")
    Rails.logger.info("Study Assist content unavailable: #{e.message}")
    render json: { error: t("Content isn't available for study tools.") }, status: :unprocessable_content
  rescue StudyAssist::ContentTooLarge
    record_metric(tool_tag(request_body[:prompt]), "too_large")
    render json: { error: t("Content is too long for study tools.") }, status: :unprocessable_content
  rescue StudyAssist::RateLimited => e
    record_metric(tool_tag(request_body[:prompt]), "rate_limit")
    Rails.logger.warn("Study Assist rate limit: #{e.message}")
    render json: { error: t("You've hit the study tools rate limit. Try again later.") }, status: :too_many_requests
  rescue StudyAssist::CedarUnavailable => e
    record_metric(tool_tag(request_body[:prompt]), "cedar_error")
    Rails.logger.error("Study Assist Cedar failure: #{e.message}")
    render json: { error: t("Study tools are temporarily unavailable. Please try again.") }, status: :bad_gateway
  end

  private

  def require_study_assist_enabled
    return if @context.is_a?(Course) && @context.feature_enabled?(:study_assist)

    render json: { error: t("Study tools aren't enabled for this course.") }, status: :not_found
    false
  end

  def require_student_access
    authorized_action(@context, @current_user, :participate_as_student)
  end

  def require_cedar_enabled
    return if CedarClient.enabled?

    render json: { error: t("Study tools are temporarily unavailable.") }, status: :service_unavailable
    false
  end

  def assist_request_params
    raw_state = params[:state]
    state_hash =
      case raw_state
      when ActionController::Parameters then raw_state.to_unsafe_h.with_indifferent_access
      when Hash then raw_state.with_indifferent_access
      else {}
      end

    {
      prompt: params[:prompt].to_s,
      regenerate: params[:regenerate],
      state: state_hash
    }.with_indifferent_access
  end

  def valid_request?(body)
    prompt = body[:prompt].to_s
    if prompt.bytesize > MAX_PROMPT_BYTES
      render json: { error: t("Prompt is too long.") }, status: :unprocessable_content
      return false
    end

    state = body[:state]
    if state.present?
      state_course_id = state[:courseID]
      if state_course_id.present? && state_course_id.to_s != @context.id.to_s
        render json: { error: t("State courseID must match the path course_id.") }, status: :unprocessable_content
        return false
      end
    end

    true
  end

  def record_metric(tool, result)
    InstStatsd::Statsd.distributed_increment(
      "study_assist.request",
      tags: { tool:, result: }
    )
  end

  def tool_tag(prompt)
    StudyAssist::Service.tool_key_for(prompt).to_s
  end
end
