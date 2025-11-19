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
  class AwsTranslator < BaseTranslator
    def initialize
      super
      @client = create_translation_client
    rescue => e
      Rails.logger.error("Failed to create translation client: #{e.message}")
    end

    def available?
      @client.present?
    end

    def translate_text(text:, tgt_lang:, options: {})
      return unless available?
      return if tgt_lang.nil?

      type = options[:feature_slug]

      result = @client.translate_text({
                                        text:,
                                        source_language_code: "auto",
                                        target_language_code: tgt_lang,
                                      })
      check_same_language(result.source_language_code, result.target_language_code)
      collect_translation_stats(src_lang: result.source_language_code, tgt_lang: result.target_language_code, type:)
      result.translated_text
    end

    def translate_html(html_string:, tgt_lang:, options: {})
      return unless available?
      return if tgt_lang.nil?

      type = options[:feature_slug]
      result = @client.translate_document({
                                            document: {
                                              content: html_string,
                                              content_type: "text/html",
                                            },
                                            source_language_code: "auto",
                                            target_language_code: tgt_lang,
                                          })
      check_same_language(result.source_language_code, result.target_language_code)
      collect_translation_stats(src_lang: result.source_language_code, tgt_lang: result.target_language_code, type:)
      result.translated_document.content
    end

    def self.languages
      [
        { id: "af", name: I18n.t("Afrikaans"), translated_to_name: I18n.t("Translated to Afrikaans") },
        { id: "sq", name: I18n.t("Albanian"), translated_to_name: I18n.t("Translated to Albanian") },
        { id: "am", name: I18n.t("Amharic"), translated_to_name: I18n.t("Translated to Amharic") },
        { id: "ar", name: I18n.t("Arabic"), translated_to_name: I18n.t("Translated to Arabic") },
        { id: "hy", name: I18n.t("Armenian"), translated_to_name: I18n.t("Translated to Armenian") },
        { id: "az", name: I18n.t("Azerbaijani"), translated_to_name: I18n.t("Translated to Azerbaijani") },
        { id: "bn", name: I18n.t("Bengali"), translated_to_name: I18n.t("Translated to Bengali") },
        { id: "bs", name: I18n.t("Bosnian"), translated_to_name: I18n.t("Translated to Bosnian") },
        { id: "bg", name: I18n.t("Bulgarian"), translated_to_name: I18n.t("Translated to Bulgarian") },
        { id: "ca", name: I18n.t("Catalan"), translated_to_name: I18n.t("Translated to Catalan") },
        { id: "zh", name: I18n.t("Chinese (Simplified)"), translated_to_name: I18n.t("Translated to Chinese (Simplified)") },
        { id: "zh-TW", name: I18n.t("Chinese (Traditional)"), translated_to_name: I18n.t("Translated to Chinese (Traditional)") },
        { id: "hr", name: I18n.t("Croatian"), translated_to_name: I18n.t("Translated to Croatian") },
        { id: "cs", name: I18n.t("Czech"), translated_to_name: I18n.t("Translated to Czech") },
        { id: "da", name: I18n.t("Danish"), translated_to_name: I18n.t("Translated to Danish") },
        { id: "fa-AF", name: I18n.t("Dari"), translated_to_name: I18n.t("Translated to Dari") },
        { id: "nl", name: I18n.t("Dutch"), translated_to_name: I18n.t("Translated to Dutch") },
        { id: "en", name: I18n.t("English"), translated_to_name: I18n.t("Translated to English") },
        { id: "et", name: I18n.t("Estonian"), translated_to_name: I18n.t("Translated to Estonian") },
        { id: "fa", name: I18n.t("Farsi (Persian)"), translated_to_name: I18n.t("Translated to Farsi (Persian)") },
        { id: "tl", name: I18n.t("Filipino, Tagalog"), translated_to_name: I18n.t("Translated to Filipino, Tagalog") },
        { id: "fi", name: I18n.t("Finnish"), translated_to_name: I18n.t("Translated to Finnish") },
        { id: "fr", name: I18n.t("French"), translated_to_name: I18n.t("Translated to French") },
        { id: "fr-CA", name: I18n.t("French (Canada)"), translated_to_name: I18n.t("Translated to French (Canada)") },
        { id: "ka", name: I18n.t("Georgian"), translated_to_name: I18n.t("Translated to Georgian") },
        { id: "de", name: I18n.t("German"), translated_to_name: I18n.t("Translated to German") },
        { id: "el", name: I18n.t("Greek"), translated_to_name: I18n.t("Translated to Greek") },
        { id: "gu", name: I18n.t("Gujarati"), translated_to_name: I18n.t("Translated to Gujarati") },
        { id: "ht", name: I18n.t("Haitian Creole"), translated_to_name: I18n.t("Translated to Haitian Creole") },
        { id: "ha", name: I18n.t("Hausa"), translated_to_name: I18n.t("Translated to Hausa") },
        { id: "he", name: I18n.t("Hebrew"), translated_to_name: I18n.t("Translated to Hebrew") },
        { id: "hi", name: I18n.t("Hindi"), translated_to_name: I18n.t("Translated to Hindi") },
        { id: "hu", name: I18n.t("Hungarian"), translated_to_name: I18n.t("Translated to Hungarian") },
        { id: "is", name: I18n.t("Icelandic"), translated_to_name: I18n.t("Translated to Icelandic") },
        { id: "id", name: I18n.t("Indonesian"), translated_to_name: I18n.t("Translated to Indonesian") },
        { id: "ga", name: I18n.t("Irish"), translated_to_name: I18n.t("Translated to Irish") },
        { id: "it", name: I18n.t("Italian"), translated_to_name: I18n.t("Translated to Italian") },
        { id: "ja", name: I18n.t("Japanese"), translated_to_name: I18n.t("Translated to Japanese") },
        { id: "kn", name: I18n.t("Kannada"), translated_to_name: I18n.t("Translated to Kannada") },
        { id: "kk", name: I18n.t("Kazakh"), translated_to_name: I18n.t("Translated to Kazakh") },
        { id: "ko", name: I18n.t("Korean"), translated_to_name: I18n.t("Translated to Korean") },
        { id: "lv", name: I18n.t("Latvian"), translated_to_name: I18n.t("Translated to Latvian") },
        { id: "lt", name: I18n.t("Lithuanian"), translated_to_name: I18n.t("Translated to Lithuanian") },
        { id: "mk", name: I18n.t("Macedonian"), translated_to_name: I18n.t("Translated to Macedonian") },
        { id: "ms", name: I18n.t("Malay"), translated_to_name: I18n.t("Translated to Malay") },
        { id: "ml", name: I18n.t("Malayalam"), translated_to_name: I18n.t("Translated to Malayalam") },
        { id: "mt", name: I18n.t("Maltese"), translated_to_name: I18n.t("Translated to Maltese") },
        { id: "mr", name: I18n.t("Marathi"), translated_to_name: I18n.t("Translated to Marathi") },
        { id: "mn", name: I18n.t("Mongolian"), translated_to_name: I18n.t("Translated to Mongolian") },
        { id: "no", name: I18n.t("Norwegian (Bokmål)"), translated_to_name: I18n.t("Translated to Norwegian (Bokmål)") },
        { id: "ps", name: I18n.t("Pashto"), translated_to_name: I18n.t("Translated to Pashto") },
        { id: "pl", name: I18n.t("Polish"), translated_to_name: I18n.t("Translated to Polish") },
        { id: "pt", name: I18n.t("Portuguese (Brazil)"), translated_to_name: I18n.t("Translated to Portuguese (Brazil)") },
        { id: "pt-PT", name: I18n.t("Portuguese (Portugal)"), translated_to_name: I18n.t("Translated to Portuguese (Portugal)") },
        { id: "pa", name: I18n.t("Punjabi"), translated_to_name: I18n.t("Translated to Punjabi") },
        { id: "ro", name: I18n.t("Romanian"), translated_to_name: I18n.t("Translated to Romanian") },
        { id: "ru", name: I18n.t("Russian"), translated_to_name: I18n.t("Translated to Russian") },
        { id: "sr", name: I18n.t("Serbian"), translated_to_name: I18n.t("Translated to Serbian") },
        { id: "si", name: I18n.t("Sinhala"), translated_to_name: I18n.t("Translated to Sinhala") },
        { id: "sk", name: I18n.t("Slovak"), translated_to_name: I18n.t("Translated to Slovak") },
        { id: "sl", name: I18n.t("Slovenian"), translated_to_name: I18n.t("Translated to Slovenian") },
        { id: "so", name: I18n.t("Somali"), translated_to_name: I18n.t("Translated to Somali") },
        { id: "es", name: I18n.t("Spanish"), translated_to_name: I18n.t("Translated to Spanish") },
        { id: "es-MX", name: I18n.t("Spanish (Mexico)"), translated_to_name: I18n.t("Translated to Spanish (Mexico)") },
        { id: "sw", name: I18n.t("Swahili"), translated_to_name: I18n.t("Translated to Swahili") },
        { id: "sv", name: I18n.t("Swedish"), translated_to_name: I18n.t("Translated to Swedish") },
        { id: "ta", name: I18n.t("Tamil"), translated_to_name: I18n.t("Translated to Tamil") },
        { id: "te", name: I18n.t("Telugu"), translated_to_name: I18n.t("Translated to Telugu") },
        { id: "th", name: I18n.t("Thai"), translated_to_name: I18n.t("Translated to Thai") },
        { id: "tr", name: I18n.t("Turkish"), translated_to_name: I18n.t("Translated to Turkish") },
        { id: "uk", name: I18n.t("Ukrainian"), translated_to_name: I18n.t("Translated to Ukrainian") },
        { id: "ur", name: I18n.t("Urdu"), translated_to_name: I18n.t("Translated to Urdu") },
        { id: "uz", name: I18n.t("Uzbek"), translated_to_name: I18n.t("Translated to Uzbek") },
        { id: "vi", name: I18n.t("Vietnamese"), translated_to_name: I18n.t("Translated to Vietnamese") },
        { id: "cy", name: I18n.t("Welsh"), translated_to_name: I18n.t("Translated to Welsh") },
      ].sort_by { |language| Canvas::ICU.collation_key(language[:name]) }
    end

    private

    def create_translation_client
      config = create_client_config("translation.yml")
      if config[:credentials].set?
        Aws::Translate::Client.new(config)
      end
    end
  end
end
