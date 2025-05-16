# frozen_string_literal: true

# Copyright (C) 2023 - present Instructure, Inc.
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

require "aws-sdk-translate"
require "cld"
require "aws-sdk-sagemakerruntime"
require "pragmatic_segmenter"
require "nokogiri"

module Translation
  class SameLanguageTranslationError < StandardError
  end

  class << self
    include Aws::SageMakerRuntime
    # The languages are imported from https://docs.aws.amazon.com/translate/latest/dg/what-is-languages.html
    # TODO: Currently we don't support dialects(trim_locale function) because the currently implemented
    # language detector supports dialects that the translator does not. Probably we should migrate to the
    # automatic language detection that AWS translate provides but it needs additional discovery since
    # it incurs cost and not necessarily available in all the regions.
    # List of languages supported by our current detector: https://github.com/google/cld3
    def languages(improvements_feature_enabled)
      if improvements_feature_enabled
        return [
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

      [
        { id: "af", name: I18n.t("Afrikaans"), translated_to_name: I18n.t("Translated to Afrikaans") },
        { id: "am", name: I18n.t("Amharic"), translated_to_name: I18n.t("Translated to Amharic") },
        { id: "ar", name: I18n.t("Arabic"), translated_to_name: I18n.t("Translated to Arabic") },
        { id: "ast", name: I18n.t("Asturian"), translated_to_name: I18n.t("Translated to Asturian") },
        { id: "az", name: I18n.t("Azerbaijani"), translated_to_name: I18n.t("Translated to Azerbaijani") },
        { id: "ba", name: I18n.t("Bashkir"), translated_to_name: I18n.t("Translated to Bashkir") },
        { id: "be", name: I18n.t("Belarusian"), translated_to_name: I18n.t("Translated to Belarusian") },
        { id: "bg", name: I18n.t("Bulgarian"), translated_to_name: I18n.t("Translated to Bulgarian") },
        { id: "bn", name: I18n.t("Bengali"), translated_to_name: I18n.t("Translated to Bengali") },
        { id: "br", name: I18n.t("Breton"), translated_to_name: I18n.t("Translated to Breton") },
        { id: "bs", name: I18n.t("Bosnian"), translated_to_name: I18n.t("Translated to Bosnian") },
        { id: "ca", name: I18n.t("Catalan; Valencian"), translated_to_name: I18n.t("Translated to Catalan; Valencian") },
        { id: "ceb", name: I18n.t("Cebuano"), translated_to_name: I18n.t("Translated to Cebuano") },
        { id: "cs", name: I18n.t("Czech"), translated_to_name: I18n.t("Translated to Czech") },
        { id: "cy", name: I18n.t("Welsh"), translated_to_name: I18n.t("Translated to Welsh") },
        { id: "da", name: I18n.t("Danish"), translated_to_name: I18n.t("Translated to Danish") },
        { id: "de", name: I18n.t("German"), translated_to_name: I18n.t("Translated to German") },
        { id: "el", name: I18n.t("Greek"), translated_to_name: I18n.t("Translated to Greek") },
        { id: "en", name: I18n.t("English"), translated_to_name: I18n.t("Translated to English") },
        { id: "es", name: I18n.t("Spanish"), translated_to_name: I18n.t("Translated to Spanish") },
        { id: "et", name: I18n.t("Estonian"), translated_to_name: I18n.t("Translated to Estonian") },
        { id: "fa", name: I18n.t("Persian"), translated_to_name: I18n.t("Translated to Persian") },
        { id: "ff", name: I18n.t("Fulah"), translated_to_name: I18n.t("Translated to Fulah") },
        { id: "fi", name: I18n.t("Finnish"), translated_to_name: I18n.t("Translated to Finnish") },
        { id: "fr", name: I18n.t("French"), translated_to_name: I18n.t("Translated to French") },
        { id: "fy", name: I18n.t("Western Frisian"), translated_to_name: I18n.t("Translated to Western Frisian") },
        { id: "ga", name: I18n.t("Irish"), translated_to_name: I18n.t("Translated to Irish") },
        { id: "gd", name: I18n.t("Gaelic; Scottish Gaelic"), translated_to_name: I18n.t("Translated to Gaelic; Scottish Gaelic") },
        { id: "gl", name: I18n.t("Galician"), translated_to_name: I18n.t("Translated to Galician") },
        { id: "gu", name: I18n.t("Gujarati"), translated_to_name: I18n.t("Translated to Gujarati") },
        { id: "ha", name: I18n.t("Hausa"), translated_to_name: I18n.t("Translated to Hausa") },
        { id: "he", name: I18n.t("Hebrew"), translated_to_name: I18n.t("Translated to Hebrew") },
        { id: "hi", name: I18n.t("Hindi"), translated_to_name: I18n.t("Translated to Hindi") },
        { id: "hr", name: I18n.t("Croatian"), translated_to_name: I18n.t("Translated to Croatian") },
        { id: "ht", name: I18n.t("Haitian; Haitian Creole"), translated_to_name: I18n.t("Translated to Haitian; Haitian Creole") },
        { id: "hu", name: I18n.t("Hungarian"), translated_to_name: I18n.t("Translated to Hungarian") },
        { id: "hy", name: I18n.t("Armenian"), translated_to_name: I18n.t("Translated to Armenian") },
        { id: "id", name: I18n.t("Indonesian"), translated_to_name: I18n.t("Translated to Indonesian") },
        { id: "ig", name: I18n.t("Igbo"), translated_to_name: I18n.t("Translated to Igbo") },
        { id: "ilo", name: I18n.t("Iloko"), translated_to_name: I18n.t("Translated to Iloko") },
        { id: "is", name: I18n.t("Icelandic"), translated_to_name: I18n.t("Translated to Icelandic") },
        { id: "it", name: I18n.t("Italian"), translated_to_name: I18n.t("Translated to Italian") },
        { id: "ja", name: I18n.t("Japanese"), translated_to_name: I18n.t("Translated to Japanese") },
        { id: "jv", name: I18n.t("Javanese"), translated_to_name: I18n.t("Translated to Javanese") },
        { id: "ka", name: I18n.t("Georgian"), translated_to_name: I18n.t("Translated to Georgian") },
        { id: "kk", name: I18n.t("Kazakh"), translated_to_name: I18n.t("Translated to Kazakh") },
        { id: "km", name: I18n.t("Central Khmer"), translated_to_name: I18n.t("Translated to Central Khmer") },
        { id: "kn", name: I18n.t("Kannada"), translated_to_name: I18n.t("Translated to Kannada") },
        { id: "ko", name: I18n.t("Korean"), translated_to_name: I18n.t("Translated to Korean") },
        { id: "lb", name: I18n.t("Luxembourgish; Letzeburgesch"), translated_to_name: I18n.t("Translated to Luxembourgish; Letzeburgesch") },
        { id: "lg", name: I18n.t("Ganda"), translated_to_name: I18n.t("Translated to Ganda") },
        { id: "ln", name: I18n.t("Lingala"), translated_to_name: I18n.t("Translated to Lingala") },
        { id: "lo", name: I18n.t("Lao"), translated_to_name: I18n.t("Translated to Lao") },
        { id: "lt", name: I18n.t("Lithuanian"), translated_to_name: I18n.t("Translated to Lithuanian") },
        { id: "lv", name: I18n.t("Latvian"), translated_to_name: I18n.t("Translated to Latvian") },
        { id: "mg", name: I18n.t("Malagasy"), translated_to_name: I18n.t("Translated to Malagasy") },
        { id: "mk", name: I18n.t("Macedonian"), translated_to_name: I18n.t("Translated to Macedonian") },
        { id: "ml", name: I18n.t("Malayalam"), translated_to_name: I18n.t("Translated to Malayalam") },
        { id: "mn", name: I18n.t("Mongolian"), translated_to_name: I18n.t("Translated to Mongolian") },
        { id: "mr", name: I18n.t("Marathi"), translated_to_name: I18n.t("Translated to Marathi") },
        { id: "ms", name: I18n.t("Malay"), translated_to_name: I18n.t("Translated to Malay") },
        { id: "my", name: I18n.t("Burmese"), translated_to_name: I18n.t("Translated to Burmese") },
        { id: "ne", name: I18n.t("Nepali"), translated_to_name: I18n.t("Translated to Nepali") },
        { id: "nl", name: I18n.t("Dutch; Flemish"), translated_to_name: I18n.t("Translated to Dutch; Flemish") },
        { id: "no", name: I18n.t("Norwegian"), translated_to_name: I18n.t("Translated to Norwegian") },
        { id: "ns", name: I18n.t("Northern Sotho"), translated_to_name: I18n.t("Translated to Northern Sotho") },
        { id: "oc", name: I18n.t("Occitan (post 1500)"), translated_to_name: I18n.t("Translated to Occitan (post 1500)") },
        { id: "or", name: I18n.t("Oriya"), translated_to_name: I18n.t("Translated to Oriya") },
        { id: "pa", name: I18n.t("Panjabi; Punjabi"), translated_to_name: I18n.t("Translated to Panjabi; Punjabi") },
        { id: "pl", name: I18n.t("Polish"), translated_to_name: I18n.t("Translated to Polish") },
        { id: "ps", name: I18n.t("Pushto; Pashto"), translated_to_name: I18n.t("Translated to Pushto; Pashto") },
        { id: "pt", name: I18n.t("Portuguese"), translated_to_name: I18n.t("Translated to Portuguese") },
        { id: "ro", name: I18n.t("Romanian; Moldavian; Moldovan"), translated_to_name: I18n.t("Translated to Romanian; Moldavian; Moldovan") },
        { id: "ru", name: I18n.t("Russian"), translated_to_name: I18n.t("Translated to Russian") },
        { id: "sd", name: I18n.t("Sindhi"), translated_to_name: I18n.t("Translated to Sindhi") },
        { id: "si", name: I18n.t("Sinhala; Sinhalese"), translated_to_name: I18n.t("Translated to Sinhala; Sinhalese") },
        { id: "sk", name: I18n.t("Slovak"), translated_to_name: I18n.t("Translated to Slovak") },
        { id: "sl", name: I18n.t("Slovenian"), translated_to_name: I18n.t("Translated to Slovenian") },
        { id: "so", name: I18n.t("Somali"), translated_to_name: I18n.t("Translated to Somali") },
        { id: "sq", name: I18n.t("Albanian"), translated_to_name: I18n.t("Translated to Albanian") },
        { id: "sr", name: I18n.t("Serbian"), translated_to_name: I18n.t("Translated to Serbian") },
        { id: "ss", name: I18n.t("Swati"), translated_to_name: I18n.t("Translated to Swati") },
        { id: "su", name: I18n.t("Sundanese"), translated_to_name: I18n.t("Translated to Sundanese") },
        { id: "sv", name: I18n.t("Swedish"), translated_to_name: I18n.t("Translated to Swedish") },
        { id: "sw", name: I18n.t("Swahili"), translated_to_name: I18n.t("Translated to Swahili") },
        { id: "ta", name: I18n.t("Tamil"), translated_to_name: I18n.t("Translated to Tamil") },
        { id: "th", name: I18n.t("Thai"), translated_to_name: I18n.t("Translated to Thai") },
        { id: "tl", name: I18n.t("Tagalog"), translated_to_name: I18n.t("Translated to Tagalog") },
        { id: "tn", name: I18n.t("Tswana"), translated_to_name: I18n.t("Translated to Tswana") },
        { id: "tr", name: I18n.t("Turkish"), translated_to_name: I18n.t("Translated to Turkish") },
        { id: "uk", name: I18n.t("Ukrainian"), translated_to_name: I18n.t("Translated to Ukrainian") },
        { id: "ur", name: I18n.t("Urdu"), translated_to_name: I18n.t("Translated to Urdu") },
        { id: "uz", name: I18n.t("Uzbek"), translated_to_name: I18n.t("Translated to Uzbek") },
        { id: "vi", name: I18n.t("Vietnamese"), translated_to_name: I18n.t("Translated to Vietnamese") },
        { id: "wo", name: I18n.t("Wolof"), translated_to_name: I18n.t("Translated to Wolof") },
        { id: "xh", name: I18n.t("Xhosa"), translated_to_name: I18n.t("Translated to Xhosa") },
        { id: "yi", name: I18n.t("Yiddish"), translated_to_name: I18n.t("Translated to Yiddish") },
        { id: "yo", name: I18n.t("Yoruba"), translated_to_name: I18n.t("Translated to Yoruba") },
        { id: "zh", name: I18n.t("Chinese"), translated_to_name: I18n.t("Translated to Chinese") },
        { id: "zu", name: I18n.t("Zulu"), translated_to_name: I18n.t("Translated to Zulu") }
      ].sort_by { |language| Canvas::ICU.collation_key(language[:name]) }
    end

    delegate :logger, to: :Rails

    def translation_client
      @translation_client ||= create_translation_client
    end

    def sagemaker_client
      @sagemaker_client ||= create_sagemaker_client
    end

    def available?(context, feature_flag, improvements_feature_enabled)
      Rails.logger.info("Checking if translation is available")
      return false unless context&.feature_enabled?(feature_flag)

      if improvements_feature_enabled
        translation_client.present?
      else
        sagemaker_client.present?
      end
    end

    def translate_text(text:, tgt_lang:)
      return unless translation_client.present?
      return if tgt_lang.nil?

      result = translation_client.translate_text({
                                                   text:,
                                                   source_language_code: "auto",
                                                   target_language_code: tgt_lang,
                                                 })

      check_same_language(result)
      tags = ["type:inbox", "source_language:#{result.source_language_code}", "dest_language:#{result.target_language_code}"]
      InstStatsd::Statsd.distributed_increment("translation.invocations", tags:)
      result.translated_text
    end

    def translate_html(html_string:, tgt_lang:)
      return unless translation_client.present?
      return if tgt_lang.nil?

      result = translation_client.translate_document({
                                                       document: {
                                                         content: html_string,
                                                         content_type: "text/html",
                                                       },
                                                       source_language_code: "auto",
                                                       target_language_code: tgt_lang,
                                                     })

      check_same_language(result)
      tags = ["type:discussion", "source_language:#{result.source_language_code}", "dest_language:#{result.target_language_code}"]
      InstStatsd::Statsd.distributed_increment("translation.invocations", tags:)
      result.translated_document.content
    end

    def translate_html_sagemaker(html_string:, user: nil, src_lang: nil, tgt_lang: nil)
      # Parse the document into a nokogiri fragment, needed to maintain the structure of the message
      # Gather up all the translations that need to happen.
      # With those translations, piece the document back together and return the to_html version of that
      # back to the client.
      fragment = Nokogiri::HTML.fragment(html_string)
      translations = []
      # Initialize our search
      to_visit = fragment.children
      # Walk the tree.
      current = nil
      until to_visit.empty?
        current = to_visit.shift
        if current.text? && !current.content.gsub(/[[:space:]]+/, "").empty? # Remove whitespace strings, including NBSP
          translations << current
        else
          current.children.each { |child| to_visit << child }
        end
      end
      # Do the translations
      translations.each do |translation|
        translation.content = Translation.create(text: translation.content, user:, src_lang:, tgt_lang:)
      end
      fragment.to_html
    end

    def translate_message_sagemaker(text:, user:)
      translated_text = []
      src_lang = trim_locale(CLD.detect_language(text)[:code])
      tgt_lang = if user.locale.nil?
                   "en"
                 else
                   trim_locale(user.locale)
                 end
      text.split("\n").map do |paragraph|
        passage = []
        PragmaticSegmenter::Segmenter.new(text: paragraph, language: src_lang).segment.each do |segment|
          trans = create(src_lang:, tgt_lang:, text: segment)
          passage << trans
        end
        translated_text << passage.join
      end
      translated_text.join("\n")
    end

    def create(text:, user: nil, src_lang: nil, tgt_lang: nil)
      return unless sagemaker_client.present?
      return if tgt_lang.nil? && user.nil?

      # If source lang was not set, then detect the language.
      if src_lang.nil?
        result = trim_locale(CLD.detect_language(text)[:code])
        if result == "un" # Unknown language code.
          logger.warn("Could not detect language from src text, defaulting to English")
          src_lang = "en"
        else
          src_lang = result
        end
      end
      # If target lang was nil, then user must be set. Try to get locale from the user.
      if tgt_lang.nil?
        tgt_lang = trim_locale(user.locale)
      end
      InstStatsd::Statsd.distributed_increment("translation.create.#{src_lang}.#{tgt_lang}")
      # TODO: Error handling of invoke endpoint.
      response = sagemaker_client.invoke_endpoint(
        endpoint_name: @endpoint,
        body: { inputs: { src_lang:, tgt_lang:, text: } }.to_json,
        content_type: "application/json",
        accept: "application/json"
      )
      JSON.parse(response.body.read)
    end

    private

    def check_same_language(translation_result)
      raise SameLanguageTranslationError if translation_result.source_language_code == translation_result.target_language_code
    end

    def parse_src_lang(text)
      result = trim_locale(CLD.detect_language(text)[:code])
      if result == "un" # Unknown language code.
        logger.warn("Could not detect language from src text, defaulting to English")
        "en"
      else
        result
      end
    end

    def trim_locale(locale)
      locale[0..1]
    end

    def create_client_config(yaml_name)
      Rails.logger.info("Creating translation client")
      settings = YAML.safe_load(DynamicSettings.find(tree: :private)[yaml_name] || "{}")
      config = {
        region: settings["translation_region"] || "us-west-2",
      }

      @endpoint = settings["endpoint_name"]

      config[:credentials] = Canvas::AwsCredentialProvider.new("translation", settings["vault_credential_path"])
      config
    end

    def create_translation_client
      config = create_client_config("translation.yml")
      if config[:credentials].set?
        Aws::Translate::Client.new(config)
      end
    end

    def create_sagemaker_client
      config = create_client_config("sagemaker.yml")
      if config[:credentials].set?
        Aws::SageMakerRuntime::Client.new(config)
      end
    end
  end
end
