# frozen_string_literal: true

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

module Translation
  class CedarTranslator < BaseTranslator
    def available?
      CedarClient.enabled?
    end

    def translate_text(text:, tgt_lang:, options: {})
      return nil unless available?
      return nil if tgt_lang.nil?

      type = options[:type]
      root_account_uuid = options[:root_account_uuid]
      feature_slug = options.fetch(:feature_slug, "content-translation")

      translation_response = CedarClient.translate_text(
        content: text,
        target_language: tgt_lang,
        feature_slug:,
        root_account_uuid:
      )

      check_same_language(translation_response.source_language, tgt_lang)
      collect_translation_stats(src_lang: translation_response.source_language, tgt_lang:, type:)
      translation_response.translation
    rescue => e
      Rails.logger.error("Cedar Translate API error during text translation: #{e.message})")
      raise e
    end

    def translate_html(html_string:, tgt_lang:, options: {})
      return nil unless available?
      return nil if tgt_lang.nil?

      root_account_uuid = options[:root_account_uuid]
      feature_slug = options.fetch(:feature_slug, "content-translation")
      type = options[:type]

      translation_response = CedarClient.translate_html(
        content: html_string,
        target_language: tgt_lang,
        feature_slug:,
        root_account_uuid:
      )

      check_same_language(translation_response.source_language, tgt_lang)
      collect_translation_stats(src_lang: translation_response.source_language, tgt_lang:, type:)
      translation_response.translation
    rescue => e
      Rails.logger.error("Cedar Translate API error during HTML translation: #{e.message} (rescued as StandardError)")
      raise e
    end

    def self.languages
      [
        { id: "ar", name: I18n.t("Arabic"), translated_to_name: I18n.t("Translated to Arabic") },
        { id: "ca", name: I18n.t("Catalan"), translated_to_name: I18n.t("Translated to Catalan") },
        { id: "cy", name: I18n.t("Welsh"), translated_to_name: I18n.t("Translated to Welsh") },
        { id: "da", name: I18n.t("Danish"), translated_to_name: I18n.t("Translated to Danish") },
        { id: "da-x-k12", name: I18n.t("Danish (K-12)"), translated_to_name: I18n.t("Translated to Danish (K-12)") },
        { id: "de", name: I18n.t("German"), translated_to_name: I18n.t("Translated to German") },
        { id: "el", name: I18n.t("Greek"), translated_to_name: I18n.t("Translated to Greek") },
        { id: "en", name: I18n.t("English"), translated_to_name: I18n.t("Translated to English") },
        { id: "en-AU", name: I18n.t("English (Australia)"), translated_to_name: I18n.t("Translated to English (Australia)") },
        { id: "en-CA", name: I18n.t("English (Canada)"), translated_to_name: I18n.t("Translated to English (Canada)") },
        { id: "en-GB", name: I18n.t("English (UK)"), translated_to_name: I18n.t("Translated to English (UK)") },
        { id: "en-US", name: I18n.t("English (US)"), translated_to_name: I18n.t("Translated to English (US)") },
        { id: "es", name: I18n.t("Spanish"), translated_to_name: I18n.t("Translated to Spanish") },
        { id: "es-ES", name: I18n.t("Spanish (Spain)"), translated_to_name: I18n.t("Translated to Spanish (Spain)") },
        { id: "fa", name: I18n.t("Farsi (Persian)"), translated_to_name: I18n.t("Translated to Farsi (Persian)") },
        { id: "fi", name: I18n.t("Finnish"), translated_to_name: I18n.t("Translated to Finnish") },
        { id: "fr", name: I18n.t("French"), translated_to_name: I18n.t("Translated to French") },
        { id: "fr-CA", name: I18n.t("French (Canada)"), translated_to_name: I18n.t("Translated to French (Canada)") },
        { id: "he", name: I18n.t("Hebrew"), translated_to_name: I18n.t("Translated to Hebrew") },
        { id: "hi", name: I18n.t("Hindi"), translated_to_name: I18n.t("Translated to Hindi") },
        { id: "ht", name: I18n.t("Haitian Creole"), translated_to_name: I18n.t("Translated to Haitian Creole") },
        { id: "hu", name: I18n.t("Hungarian"), translated_to_name: I18n.t("Translated to Hungarian") },
        { id: "hy", name: I18n.t("Armenian"), translated_to_name: I18n.t("Translated to Armenian") },
        { id: "id", name: I18n.t("Indonesian"), translated_to_name: I18n.t("Translated to Indonesian") },
        { id: "is", name: I18n.t("Icelandic"), translated_to_name: I18n.t("Translated to Icelandic") },
        { id: "it", name: I18n.t("Italian"), translated_to_name: I18n.t("Translated to Italian") },
        { id: "ja", name: I18n.t("Japanese"), translated_to_name: I18n.t("Translated to Japanese") },
        { id: "ko", name: I18n.t("Korean"), translated_to_name: I18n.t("Translated to Korean") },
        { id: "ms", name: I18n.t("Malay"), translated_to_name: I18n.t("Translated to Malay") },
        { id: "nb", name: I18n.t("Norwegian (Bokmål)"), translated_to_name: I18n.t("Translated to Norwegian (Bokmål)") },
        { id: "nb-x-k12", name: I18n.t("Norwegian (Bokmål) (K-12)"), translated_to_name: I18n.t("Translated to Norwegian (Bokmål) (K-12)") },
        { id: "nl", name: I18n.t("Dutch"), translated_to_name: I18n.t("Translated to Dutch") },
        { id: "pl", name: I18n.t("Polish"), translated_to_name: I18n.t("Translated to Polish") },
        { id: "pt", name: I18n.t("Portuguese"), translated_to_name: I18n.t("Translated to Portuguese") },
        { id: "pt-BR", name: I18n.t("Portuguese (Brazil)"), translated_to_name: I18n.t("Translated to Portuguese (Brazil)") },
        { id: "pt-PT", name: I18n.t("Portuguese (Portugal)"), translated_to_name: I18n.t("Translated to Portuguese (Portugal)") },
        { id: "ru", name: I18n.t("Russian"), translated_to_name: I18n.t("Translated to Russian") },
        { id: "sl", name: I18n.t("Slovenian"), translated_to_name: I18n.t("Translated to Slovenian") },
        { id: "sv", name: I18n.t("Swedish"), translated_to_name: I18n.t("Translated to Swedish") },
        { id: "sv-x-k12", name: I18n.t("Swedish (K-12)"), translated_to_name: I18n.t("Translated to Swedish (K-12)") },
        { id: "th", name: I18n.t("Thai"), translated_to_name: I18n.t("Translated to Thai") },
        { id: "tr", name: I18n.t("Turkish"), translated_to_name: I18n.t("Translated to Turkish") },
        { id: "uk", name: I18n.t("Ukrainian"), translated_to_name: I18n.t("Translated to Ukrainian") },
        { id: "vi", name: I18n.t("Vietnamese"), translated_to_name: I18n.t("Translated to Vietnamese") },
        { id: "zh-Hans", name: I18n.t("Chinese (Simplified)"), translated_to_name: I18n.t("Translated to Chinese (Simplified)") },
        { id: "zh-Hant", name: I18n.t("Chinese (Traditional)"), translated_to_name: I18n.t("Translated to Chinese (Traditional)") },
      ].sort_by { |language| Canvas::ICU.collation_key(language[:name]) }
    end
  end
end
