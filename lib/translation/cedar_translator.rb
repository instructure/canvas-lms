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

      root_account_uuid = options[:root_account_uuid]
      feature_slug = options.fetch(:feature_slug)
      current_user = options.fetch(:current_user)

      translation_response = CedarClient.translate_text(
        content: text,
        target_language: tgt_lang,
        feature_slug:,
        root_account_uuid:,
        current_user:
      )

      check_same_language(translation_response.source_language, tgt_lang)
      collect_translation_stats(src_lang: translation_response.source_language, tgt_lang:, type: feature_slug)
      translation_response.translation
    rescue InstructureMiscPlugin::Extensions::CedarClient::ContentTooLongError
      raise TextTooLongError
    rescue InstructureMiscPlugin::Extensions::CedarClient::UnsupportedLanguageError
      raise UnsupportedLanguageError
    rescue InstructureMiscPlugin::Extensions::CedarClient::ValidationError
      raise ValidationError
    rescue InstructureMiscPlugin::Extensions::CedarClient::CedarLimitReachedError
      raise CedarLimitReachedError
    end

    def translate_html(html_string:, tgt_lang:, options: {})
      return nil unless available?
      return nil if tgt_lang.nil?

      root_account_uuid = options[:root_account_uuid]
      feature_slug = options.fetch(:feature_slug)
      current_user = options.fetch(:current_user)

      translation_response = CedarClient.translate_html(
        content: html_string,
        target_language: tgt_lang,
        feature_slug:,
        root_account_uuid:,
        current_user:
      )

      check_same_language(translation_response.source_language, tgt_lang)
      collect_translation_stats(src_lang: translation_response.source_language, tgt_lang:, type: feature_slug)
      translation_response.translation
    rescue InstructureMiscPlugin::Extensions::CedarClient::ContentTooLongError
      raise TextTooLongError
    rescue InstructureMiscPlugin::Extensions::CedarClient::UnsupportedLanguageError
      raise UnsupportedLanguageError
    rescue InstructureMiscPlugin::Extensions::CedarClient::ValidationError
      raise ValidationError
    rescue InstructureMiscPlugin::Extensions::CedarClient::CedarLimitReachedError
      raise CedarLimitReachedError
    end

    def self.languages
      [
        { id: "ca", name: I18n.t("Catalan"), translated_to_name: I18n.t("Translated to Catalan") },
        { id: "de", name: I18n.t("German"), translated_to_name: I18n.t("Translated to German") },
        { id: "en", name: I18n.t("English"), translated_to_name: I18n.t("Translated to English") },
        { id: "es", name: I18n.t("Spanish"), translated_to_name: I18n.t("Translated to Spanish") },
        { id: "fr", name: I18n.t("French"), translated_to_name: I18n.t("Translated to French") },
        { id: "nl", name: I18n.t("Dutch"), translated_to_name: I18n.t("Translated to Dutch") },
        { id: "pt-BR", name: I18n.t("Portuguese (Brazil)"), translated_to_name: I18n.t("Translated to Portuguese (Brazil)") },
        { id: "ru", name: I18n.t("Russian"), translated_to_name: I18n.t("Translated to Russian") },
        { id: "sv", name: I18n.t("Swedish"), translated_to_name: I18n.t("Translated to Swedish") },
        { id: "zh-Hans", name: I18n.t("Chinese (Simplified)"), translated_to_name: I18n.t("Translated to Chinese (Simplified)") },
      ].sort_by { |language| Canvas::ICU.collation_key(language[:name]) }
    end
  end
end
