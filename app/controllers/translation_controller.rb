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
  require "aws-sdk-translate"

  before_action :require_context, only: :translate
  before_action :require_user
  before_action :require_inbox_translation, only: %i[translate_paragraph]

  # Skip the authenticity token as this is an API endpoint.
  skip_before_action :verify_authenticity_token, only: [:translate]

  rescue_from Translation::TranslationError, with: :handle_translation_error
  rescue_from Aws::Translate::Errors::ServiceError, with: :handle_generic_error

  def translate
    start_time = Time.zone.now
    # Don't allow users that can't access, or if translation is not available
    translation_flags = Translation.get_translation_flags(@context.feature_enabled?(:translation), @domain_root_account)
    return render_unauthorized_action unless Translation.available?(translation_flags) && user_can_read?

    translated_text = Translation.translate_html(html_string: required_params[:text],
                                                 tgt_lang: required_params[:tgt_lang],
                                                 flags: translation_flags,
                                                 options: {
                                                   root_account_uuid: @domain_root_account.uuid,
                                                   feature_slug: required_params[:feature_slug],
                                                   current_user: @current_user
                                                 })

    render json: { translated_text: }
    if Translation.current_translation_provider_type(translation_flags) == Translation::TranslationType::AWS_TRANSLATE
      duration = Time.zone.now - start_time
      InstStatsd::Statsd.timing("translation.discussions.duration", duration)
    end
  end

  def translate_paragraph
    start_time = Time.zone.now
    # Right now course is always undefined
    translation_flags = Translation.get_translation_flags(@domain_root_account.feature_enabled?(:translate_inbox_messages), @domain_root_account)
    translated_text = Translation.translate_text(
      text: required_params[:text],
      tgt_lang: required_params[:tgt_lang],
      flags: translation_flags,
      options: {
        root_account_uuid: @domain_root_account.uuid,
        feature_slug: required_params[:feature_slug],
        current_user: @current_user
      }
    )
    if Translation.current_translation_provider_type(translation_flags) == Translation::TranslationType::AWS_TRANSLATE
      duration = Time.zone.now - start_time
      InstStatsd::Statsd.timing("translation.inbox_compose.duration", duration)
    end
    render json: { translated_text: }
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
    when Translation::CedarLimitReachedError
      tags = ["error:rate_limit"]
      message = I18n.t("The translation service is currently at capacity, please try again.")
      status = :too_many_requests
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

  def handle_generic_error(exception)
    translation_flags = Translation.get_translation_flags(@context, @domain_root_account)
    tags = []
    case exception
    when Aws::Translate::Errors::UnsupportedLanguagePairException
      error_data = JSON.parse(exception.context.http_response.body.read)
      source_lang_code = error_data["SourceLanguageCode"]
      target_lang_code = error_data["TargetLanguageCode"]
      tags = ["error:unsupported_language_pair", "source_language:#{source_lang_code}", "dest_language:#{target_lang_code}"]
      source_lang = Translation.languages(translation_flags).find { |lang| lang[:id] == source_lang_code }
      target_lang = Translation.languages(translation_flags).find { |lang| lang[:id] == target_lang_code }
      message = I18n.t("Translation from %{source_lang} to %{target_lang} is not supported.", { source_lang: source_lang[:name], target_lang: target_lang[:name] })
      status = :unprocessable_entity
    when Aws::Translate::Errors::DetectedLanguageLowConfidenceException
      tags = ["error:low_confidence"]
      message = I18n.t("Couldn’t identify source language.")
      status = :unprocessable_entity
    when Aws::Translate::Errors::TextSizeLimitExceededException
      tags = ["error:text_size_limit"]
      message = I18n.t("Translation failed because the text is longer than the character limit (5000).")
      status = :unprocessable_entity
    else
      # Generic response for all other ServiceErrors
      tags = ["error:generic"]
      message = I18n.t("There was an unexpected error during translation.")
      status = :internal_server_error
    end

    InstStatsd::Statsd.distributed_increment("translation.errors", tags:)

    render(json: { translationErrorTextTooLong: { type: "error", message: } }, status:) and return if action_name == "translate_paragraph" && tags == ["error:text_size_limit"]

    render json: { translationError: { type: "error", message: } }, status:
  end

  private

  def required_params
    params.require(:inputs).permit(:src_lang, :tgt_lang, :text, :feature_slug)
  end

  def user_can_read?
    @context.grants_right?(@current_user, session, :read)
  end

  def require_inbox_translation
    render_unauthorized_action unless Translation.available?(Translation.get_translation_flags(@domain_root_account.feature_enabled?(:translate_inbox_messages), @domain_root_account))
  end
end
