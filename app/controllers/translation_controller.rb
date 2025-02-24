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
  require "pragmatic_segmenter"
  require "aws-sdk-translate"

  before_action :require_context, only: :translate
  before_action :require_user
  before_action :require_inbox_translation, only: %i[translate_paragraph]

  # Skip the authenticity token as this is an API endpoint.
  skip_before_action :verify_authenticity_token, only: [:translate]

  rescue_from Translation::SameLanguageTranslationError, with: :handle_same_language_error
  rescue_from Aws::Translate::Errors::ServiceError, with: :handle_generic_error

  def translate
    # Don't allow users that can't access, or if translation is not available
    return render_unauthorized_action unless Translation.available?(@context, :translation) && user_can_read?

    InstStatsd::Statsd.increment("translation.discussions")
    if Account.site_admin.feature_enabled?(:ai_translation_improvements)
      render json: { translated_text: Translation.translate_html(html_string: required_params[:text],
                                                                 tgt_lang: required_params[:tgt_lang]) }
    else
      render json: { translated_text: Translation.translate_html_sagemaker(html_string: required_params[:text],
                                                                           src_lang: required_params[:src_lang],
                                                                           tgt_lang: required_params[:tgt_lang]) }
    end
  end

  def translate_paragraph
    InstStatsd::Statsd.increment("translation.inbox_compose")
    if Account.site_admin.feature_enabled?(:ai_translation_improvements)
      render json: { translated_text: Translation.translate_text(text: required_params[:text],
                                                                 tgt_lang: required_params[:tgt_lang]) }
    else
      render json: translate_large_passage(original_text: required_params[:text],
                                           src_lang: required_params[:src_lang],
                                           tgt_lang: required_params[:tgt_lang])
    end
  end

  def handle_same_language_error
    render json: { translationError: { type: "info", message: I18n.t("Translation is identical to source language.") } }, status: :unprocessable_entity
  end

  def handle_generic_error(exception)
    case exception
    when Aws::Translate::Errors::UnsupportedLanguagePairException
      error_data = JSON.parse(exception.context.http_response.body.read)

      source_lang_code = error_data["SourceLanguageCode"]
      source_lang = Translation.languages.find { |lang| lang[:id] == source_lang_code }
      target_lang_code = error_data["TargetLanguageCode"]
      target_lang = Translation.languages.find { |lang| lang[:id] == target_lang_code }

      render json: { translationError: { type: "error",
                                         message: I18n.t("Translation from %{source_lang} to %{target_lang} is not supported.", {
                                                           source_lang: source_lang[:name],
                                                           target_lang: target_lang[:name]
                                                         }) } },
             status: :unprocessable_entity
    when Aws::Translate::Errors::DetectedLanguageLowConfidenceException
      render json: { translationError: { type: "error", message: I18n.t("Couldn’t identify source language.") } }, status: :unprocessable_entity
    when Aws::Translate::Errors::TextSizeLimitExceededException
      render json: { translationError: { type: "error", message: I18n.t("Couldn’t translate because the text is too long.") } }, status: :unprocessable_entity
    else
      # Generic response for all other ServiceErrors
      render json: { translationError: { type: "error", message: I18n.t("There was an unexpected error during translation.") } }, status: :internal_server_error
    end
  end

  private

  def translate_large_passage(original_text:, src_lang:, tgt_lang:)
    # Split into paragraphs.
    text = []
    original_text.split("\n").map do |paragraph|
      # Translate the paragraph
      passage = []
      PragmaticSegmenter::Segmenter.new(text: paragraph, language: src_lang).segment.each do |segment|
        trans = Translation.create(tgt_lang:,
                                   src_lang:,
                                   text: segment)
        passage.append(trans)
      end
      text.append(passage.join)
    end
    { translated_text: text.join("\n") }
  end

  def required_params
    params.require(:inputs).permit(:src_lang, :tgt_lang, :text)
  end

  def user_can_read?
    @context.grants_right?(@current_user, session, :read)
  end

  def require_inbox_translation
    render_unauthorized_action unless Translation.available?(@domain_root_account, :translate_inbox_messages)
  end
end
