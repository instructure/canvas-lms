# frozen_string_literal: true

# Copyright (C) 2024 - present Instructure, Inc.
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

class TranslationController < ApplicationController
  before_action :require_context, only: %i[translate translation_feedback]
  before_action :require_user, only: %i[translation_feedback]
  before_action :require_inbox_translation, only: %i[translate_paragraph]

  # Skip the authenticity token as this is an API endpoint.
  skip_before_action :verify_authenticity_token, only: %i[translate translation_feedback]

  rescue_from Translation::TranslationError, with: :handle_translation_error

  def translate
    # Don't allow users that can't access, or if translation is not available
    return render_unauthorized_action unless Translation.available? && user_can_read? && @context.feature_enabled?(:translation)

    start_time = Time.zone.now
    translated_text = Translation.translate_html(html_string: required_params[:text],
                                                 tgt_lang: required_params[:tgt_lang],
                                                 options: {
                                                   root_account_uuid: @domain_root_account.uuid,
                                                   feature_slug: required_params[:feature_slug],
                                                   current_user: @current_user
                                                 })

    duration = Time.zone.now - start_time
    InstStatsd::Statsd.timing("translation.discussions.duration", duration)
    render json: { translated_text: }
  end

  def translate_paragraph
    # Right now course is always undefined
    start_time = Time.zone.now
    translated_text = Translation.translate_text(
      text: required_params[:text],
      tgt_lang: required_params[:tgt_lang],
      options: {
        root_account_uuid: @domain_root_account.uuid,
        feature_slug: required_params[:feature_slug],
        current_user: @current_user
      }
    )
    duration = Time.zone.now - start_time
    InstStatsd::Statsd.timing("translation.inbox_compose.duration", duration)
    render json: { translated_text: }
  end

  def translation_feedback
    return render_unauthorized_action unless Translation.available? &&
                                             user_can_read? &&
                                             @context.feature_enabled?(:translation) &&
                                             @context.feature_enabled?(:translation_feedback)

    content_type = params[:content_type]
    unless %w[DiscussionTopic DiscussionEntry].include?(content_type)
      return render(json: { error: "Invalid content type." }, status: :bad_request)
    end

    return render(json: { error: "Missing content_id." }, status: :bad_request) if params[:content_id].blank?
    return render(json: { error: "Missing target_language." }, status: :bad_request) if params[:target_language].blank?

    action = params[:_action]&.to_sym
    unless %i[like dislike reset_like].include?(action)
      return render(json: { error: "Invalid action." }, status: :bad_request)
    end

    find_params = {
      user: @current_user,
      context: @context,
      target_language: params[:target_language]
    }
    if content_type == "DiscussionTopic"
      find_params[:discussion_topic_id] = params[:content_id]
    else
      find_params[:discussion_entry_id] = params[:content_id]
    end
    feedback = TranslationFeedback.find_or_initialize_by(find_params)
    feedback.feature_slug = params[:feature_slug] if params[:feature_slug].present?

    begin
      case action
      when :like
        feedback.like
        InstStatsd::Statsd.distributed_increment("translation.feedback.liked")
      when :dislike
        feedback.dislike(notes: params[:notes])
        InstStatsd::Statsd.distributed_increment("translation.feedback.disliked")
      when :reset_like
        feedback.reset_like
        InstStatsd::Statsd.distributed_increment("translation.feedback.reset_like")
      end
    rescue ActiveRecord::RecordInvalid => e
      return render(json: { error: e.message }, status: :unprocessable_content)
    end

    render(json: { liked: feedback.liked, disliked: feedback.disliked })
  end

  def handle_translation_error(exception)
    tags = []
    case exception
    when Translation::SameLanguageTranslationError
      tags = ["error:same_language"]
      message = I18n.t("Translation is identical to source language.")
      status = :unprocessable_entity
    when Translation::TextTooLongError
      tags = ["error:text_size_limit"]
      message = I18n.t("Couldn’t translate because the text is too long.")
      status = :unprocessable_entity
    when Translation::UnsupportedLanguageError
      message = I18n.t("The source or target language is not supported by the translation service.")
      status = :unprocessable_entity
    else
      # Generic response for all other ServiceErrors
      tags = ["error:generic"]
      message = I18n.t("There was an unexpected error during translation.")
      status = :internal_server_error
    end

    InstStatsd::Statsd.distributed_increment("translation.errors", tags:)

    render(json: { translationErrorTextTooLong: { type: "error", message: } }, status:) and return if action_name == "translate_paragraph" && tags == ["error:text_size_limit"]

    error_type = tags.include?("error:rate_limit") ? "rateLimitError" : "error"
    render json: { translationError: { type: error_type, message: } }, status:
  end

  private

  def required_params
    params.require(:inputs).permit(:src_lang, :tgt_lang, :text, :feature_slug)
  end

  def user_can_read?
    @context.grants_right?(@current_user, session, :read)
  end

  def require_inbox_translation
    render_unauthorized_action unless Translation.available? && @domain_root_account.feature_enabled?(:translate_inbox_messages)
  end
end
