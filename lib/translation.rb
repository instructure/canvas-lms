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
  class << self
    include Aws::SageMakerRuntime
    # The languages are imported from https://docs.aws.amazon.com/translate/latest/dg/what-is-languages.html
    # TODO: Currently we don't support dialects(trim_locale function) because the currently implemented
    # language detector supports dialects that the translator does not. Probably we should migrate to the
    # automatic language detection that AWS translate provides but it needs additional discovery since
    # it incurs cost and not necessarily available in all the regions.
    # List of languages supported by our current detector: https://github.com/google/cld3
    def languages
      if Account.site_admin.feature_enabled?(:ai_translation_improvements)
        return [
          { id: "af", name: I18n.t("Afrikaans") },
          { id: "sq", name: I18n.t("Albanian") },
          { id: "am", name: I18n.t("Amharic") },
          { id: "ar", name: I18n.t("Arabic") },
          { id: "hy", name: I18n.t("Armenian") },
          { id: "az", name: I18n.t("Azerbaijani") },
          { id: "bn", name: I18n.t("Bengali") },
          { id: "bs", name: I18n.t("Bosnian") },
          { id: "bg", name: I18n.t("Bulgarian") },
          { id: "ca", name: I18n.t("Catalan") },
          { id: "zh", name: I18n.t("Chinese (Simplified)") },
          { id: "zh-TW", name: I18n.t("Chinese (Traditional)") },
          { id: "hr", name: I18n.t("Croatian") },
          { id: "cs", name: I18n.t("Czech") },
          { id: "da", name: I18n.t("Danish") },
          { id: "fa-AF", name: I18n.t("Dari") },
          { id: "nl", name: I18n.t("Dutch") },
          { id: "en", name: I18n.t("English") },
          { id: "et", name: I18n.t("Estonian") },
          { id: "fa", name: I18n.t("Farsi (Persian)") },
          { id: "tl", name: I18n.t("Filipino, Tagalog") },
          { id: "fi", name: I18n.t("Finnish") },
          { id: "fr", name: I18n.t("French") },
          { id: "fr-CA", name: I18n.t("French (Canada)") },
          { id: "ka", name: I18n.t("Georgian") },
          { id: "de", name: I18n.t("German") },
          { id: "el", name: I18n.t("Greek") },
          { id: "gu", name: I18n.t("Gujarati") },
          { id: "ht", name: I18n.t("Haitian Creole") },
          { id: "ha", name: I18n.t("Hausa") },
          { id: "he", name: I18n.t("Hebrew") },
          { id: "hi", name: I18n.t("Hindi") },
          { id: "hu", name: I18n.t("Hungarian") },
          { id: "is", name: I18n.t("Icelandic") },
          { id: "id", name: I18n.t("Indonesian") },
          { id: "ga", name: I18n.t("Irish") },
          { id: "it", name: I18n.t("Italian") },
          { id: "ja", name: I18n.t("Japanese") },
          { id: "kn", name: I18n.t("Kannada") },
          { id: "kk", name: I18n.t("Kazakh") },
          { id: "ko", name: I18n.t("Korean") },
          { id: "lv", name: I18n.t("Latvian") },
          { id: "lt", name: I18n.t("Lithuanian") },
          { id: "mk", name: I18n.t("Macedonian") },
          { id: "ms", name: I18n.t("Malay") },
          { id: "ml", name: I18n.t("Malayalam") },
          { id: "mt", name: I18n.t("Maltese") },
          { id: "mr", name: I18n.t("Marathi") },
          { id: "mn", name: I18n.t("Mongolian") },
          { id: "no", name: I18n.t("Norwegian (Bokmål)") },
          { id: "ps", name: I18n.t("Pashto") },
          { id: "pl", name: I18n.t("Polish") },
          { id: "pt", name: I18n.t("Portuguese (Brazil)") },
          { id: "pt-PT", name: I18n.t("Portuguese (Portugal)") },
          { id: "pa", name: I18n.t("Punjabi") },
          { id: "ro", name: I18n.t("Romanian") },
          { id: "ru", name: I18n.t("Russian") },
          { id: "sr", name: I18n.t("Serbian") },
          { id: "si", name: I18n.t("Sinhala") },
          { id: "sk", name: I18n.t("Slovak") },
          { id: "sl", name: I18n.t("Slovenian") },
          { id: "so", name: I18n.t("Somali") },
          { id: "es", name: I18n.t("Spanish") },
          { id: "es-MX", name: I18n.t("Spanish (Mexico)") },
          { id: "sw", name: I18n.t("Swahili") },
          { id: "sv", name: I18n.t("Swedish") },
          { id: "ta", name: I18n.t("Tamil") },
          { id: "te", name: I18n.t("Telugu") },
          { id: "th", name: I18n.t("Thai") },
          { id: "tr", name: I18n.t("Turkish") },
          { id: "uk", name: I18n.t("Ukrainian") },
          { id: "ur", name: I18n.t("Urdu") },
          { id: "uz", name: I18n.t("Uzbek") },
          { id: "vi", name: I18n.t("Vietnamese") },
          { id: "cy", name: I18n.t("Welsh") },
        ]
      end

      [
        { id: "af", name: I18n.t("Afrikaans") },
        { id: "am", name: I18n.t("Amharic") },
        { id: "ar", name: I18n.t("Arabic") },
        { id: "ast", name: I18n.t("Asturian") },
        { id: "az", name: I18n.t("Azerbaijani") },
        { id: "ba", name: I18n.t("Bashkir") },
        { id: "be", name: I18n.t("Belarusian") },
        { id: "bg", name: I18n.t("Bulgarian") },
        { id: "bn", name: I18n.t("Bengali") },
        { id: "br", name: I18n.t("Breton") },
        { id: "bs", name: I18n.t("Bosnian") },
        { id: "ca", name: I18n.t("Catalan; Valencian") },
        { id: "ceb", name: I18n.t("Cebuano") },
        { id: "cs", name: I18n.t("Czech") },
        { id: "cy", name: I18n.t("Welsh") },
        { id: "da", name: I18n.t("Danish") },
        { id: "de", name: I18n.t("German") },
        { id: "el", name: I18n.t("Greek") },
        { id: "en", name: I18n.t("English") },
        { id: "es", name: I18n.t("Spanish") },
        { id: "et", name: I18n.t("Estonian") },
        { id: "fa", name: I18n.t("Persian") },
        { id: "ff", name: I18n.t("Fulah") },
        { id: "fi", name: I18n.t("Finnish") },
        { id: "fr", name: I18n.t("French") },
        { id: "fy", name: I18n.t("Western Frisian") },
        { id: "ga", name: I18n.t("Irish") },
        { id: "gd", name: I18n.t("Gaelic; Scottish Gaelic") },
        { id: "gl", name: I18n.t("Galician") },
        { id: "gu", name: I18n.t("Gujarati") },
        { id: "ha", name: I18n.t("Hausa") },
        { id: "he", name: I18n.t("Hebrew") },
        { id: "hi", name: I18n.t("Hindi") },
        { id: "hr", name: I18n.t("Croatian") },
        { id: "ht", name: I18n.t("Haitian; Haitian Creole") },
        { id: "hu", name: I18n.t("Hungarian") },
        { id: "hy", name: I18n.t("Armenian") },
        { id: "id", name: I18n.t("Indonesian") },
        { id: "ig", name: I18n.t("Igbo") },
        { id: "ilo", name: I18n.t("Iloko") },
        { id: "is", name: I18n.t("Icelandic") },
        { id: "it", name: I18n.t("Italian") },
        { id: "ja", name: I18n.t("Japanese") },
        { id: "jv", name: I18n.t("Javanese") },
        { id: "ka", name: I18n.t("Georgian") },
        { id: "kk", name: I18n.t("Kazakh") },
        { id: "km", name: I18n.t("Central Khmer") },
        { id: "kn", name: I18n.t("Kannada") },
        { id: "ko", name: I18n.t("Korean") },
        { id: "lb", name: I18n.t("Luxembourgish; Letzeburgesch") },
        { id: "lg", name: I18n.t("Ganda") },
        { id: "ln", name: I18n.t("Lingala") },
        { id: "lo", name: I18n.t("Lao") },
        { id: "lt", name: I18n.t("Lithuanian") },
        { id: "lv", name: I18n.t("Latvian") },
        { id: "mg", name: I18n.t("Malagasy") },
        { id: "mk", name: I18n.t("Macedonian") },
        { id: "ml", name: I18n.t("Malayalam") },
        { id: "mn", name: I18n.t("Mongolian") },
        { id: "mr", name: I18n.t("Marathi") },
        { id: "ms", name: I18n.t("Malay") },
        { id: "my", name: I18n.t("Burmese") },
        { id: "ne", name: I18n.t("Nepali") },
        { id: "nl", name: I18n.t("Dutch; Flemish") },
        { id: "no", name: I18n.t("Norwegian") },
        { id: "ns", name: I18n.t("Northern Sotho") },
        { id: "oc", name: I18n.t("Occitan (post 1500)") },
        { id: "or", name: I18n.t("Oriya") },
        { id: "pa", name: I18n.t("Panjabi; Punjabi") },
        { id: "pl", name: I18n.t("Polish") },
        { id: "ps", name: I18n.t("Pushto; Pashto") },
        { id: "pt", name: I18n.t("Portuguese") },
        { id: "ro", name: I18n.t("Romanian; Moldavian; Moldovan") },
        { id: "ru", name: I18n.t("Russian") },
        { id: "sd", name: I18n.t("Sindhi") },
        { id: "si", name: I18n.t("Sinhala; Sinhalese") },
        { id: "sk", name: I18n.t("Slovak") },
        { id: "sl", name: I18n.t("Slovenian") },
        { id: "so", name: I18n.t("Somali") },
        { id: "sq", name: I18n.t("Albanian") },
        { id: "sr", name: I18n.t("Serbian") },
        { id: "ss", name: I18n.t("Swati") },
        { id: "su", name: I18n.t("Sundanese") },
        { id: "sv", name: I18n.t("Swedish") },
        { id: "sw", name: I18n.t("Swahili") },
        { id: "ta", name: I18n.t("Tamil") },
        { id: "th", name: I18n.t("Thai") },
        { id: "tl", name: I18n.t("Tagalog") },
        { id: "tn", name: I18n.t("Tswana") },
        { id: "tr", name: I18n.t("Turkish") },
        { id: "uk", name: I18n.t("Ukrainian") },
        { id: "ur", name: I18n.t("Urdu") },
        { id: "uz", name: I18n.t("Uzbek") },
        { id: "vi", name: I18n.t("Vietnamese") },
        { id: "wo", name: I18n.t("Wolof") },
        { id: "xh", name: I18n.t("Xhosa") },
        { id: "yi", name: I18n.t("Yiddish") },
        { id: "yo", name: I18n.t("Yoruba") },
        { id: "zh", name: I18n.t("Chinese") },
        { id: "zu", name: I18n.t("Zulu") }
      ].sort_by { |a| a[:name] }
    end

    def logger
      Rails.logger
    end

    def translation_client
      @translation_client ||= create_translation_client
    end

    def sagemaker_client
      @sagemaker_client ||= create_sagemaker_client
    end

    def available?(context, feature_flag)
      Rails.logger.info("Checking if translation is available")
      return false unless context&.feature_enabled?(feature_flag)

      if Account.site_admin.feature_enabled?(:ai_translation_improvements)
        translation_client.present?
      else
        sagemaker_client.present?
      end
    end

    def translate_text(text:, src_lang:, tgt_lang:)
      return unless translation_client.present?
      return if tgt_lang.nil?

      src_lang = parse_src_lang(text) if src_lang.nil?
      result = translation_client.translate_text({
                                                   text: text,
                                                   source_language_code: src_lang,
                                                   target_language_code: tgt_lang,
                                                 })

      result.translated_text
    end

    def translate_html(html_string:, src_lang:, tgt_lang:)
      return unless translation_client.present?
      return if tgt_lang.nil?

      src_lang = parse_src_lang(html_string) if src_lang.nil?
      result = translation_client.translate_document({
                                                       document: {
                                                         content: html_string,
                                                         content_type: "text/html",
                                                       },
                                                       source_language_code: src_lang,
                                                       target_language_code: tgt_lang,
                                                     })

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

    def language_matches_user_locale?(user, text)
      locale = if user.locale.nil?
                 "en"
               else
                 trim_locale(user.locale)
               end
      result = trim_locale(CLD.detect_language(text)[:code])
      result == locale
    end

    def translate_message(text:, user:)
      src_lang = trim_locale(CLD.detect_language(text)[:code])
      tgt_lang = if user.locale.nil?
                   "en"
                 else
                   trim_locale(user.locale)
                 end

      translate_text(text: text, src_lang: src_lang, tgt_lang: tgt_lang)
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
