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

require "aws-sdk-sagemakerruntime"
require "cld"
require "pragmatic_segmenter"

module Translation
  class << self
    include Aws::SageMakerRuntime

    def logger
      Rails.logger
    end

    def sagemaker_client
      settings = YAML.safe_load(DynamicSettings.find(tree: :private)["sagemaker.yml"] || "{}")
      config = {
        region: settings["translation_region"] || "us-west-2",
      }

      # While reading the settings, set the endpoint value.
      @endpoint = settings["endpoint_name"]

      config[:credentials] = Canvas::AwsCredentialProvider.new("translation", settings["vault_credential_path"])
      if config[:credentials].set?
        Aws::SageMakerRuntime::Client.new(config)
      end
    end

    ##
    # Can we provide API translations?
    #
    def available?(context, feature_flag)
      context&.feature_enabled?(feature_flag) && sagemaker_client.present?
    end

    ##
    # Create a translation given the src -> target mapping
    #
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

      InstStatsd::Statsd.increment("translation.create.#{src_lang}.#{tgt_lang}")

      # TODO: Error handling of invoke endpoint.
      response = sagemaker_client.invoke_endpoint(
        endpoint_name: @endpoint,
        body: { inputs: { src_lang:, tgt_lang:, text: } }.to_json,
        content_type: "application/json",
        accept: "application/json"
      )

      JSON.parse(response.body.read)
    end

    def languages
      [
        { id: "af", name: "Afrikaans" },
        { id: "am", name: "Amharic" },
        { id: "ar", name: "Arabic" },
        { id: "ast", name: "Asturian" },
        { id: "az", name: "Azerbaijani" },
        { id: "ba", name: "Bashkir" },
        { id: "be", name: "Belarusian" },
        { id: "bg", name: "Bulgarian" },
        { id: "bn", name: "Bengali" },
        { id: "br", name: "Breton" },
        { id: "bs", name: "Bosnian" },
        { id: "ca", name: "Catalan; Valencian" },
        { id: "ceb", name: "Cebuano" },
        { id: "cs", name: "Czech" },
        { id: "cy", name: "Welsh" },
        { id: "da", name: "Danish" },
        { id: "de", name: "German" },
        { id: "el", name: "Greeek" },
        { id: "en", name: "English" },
        { id: "es", name: "Spanish" },
        { id: "et", name: "Estonian" },
        { id: "fa", name: "Persian" },
        { id: "ff", name: "Fulah" },
        { id: "fi", name: "Finnish" },
        { id: "fr", name: "French" },
        { id: "fy", name: "Western Frisian" },
        { id: "ga", name: "Irish" },
        { id: "gd", name: "Gaelic; Scottish Gaelic" },
        { id: "gl", name: "Galician" },
        { id: "gu", name: "Gujarati" },
        { id: "ha", name: "Hausa" },
        { id: "he", name: "Hebrew" },
        { id: "hi", name: "Hindi" },
        { id: "hr", name: "Croatian" },
        { id: "ht", name: "Haitian; Haitian Creole" },
        { id: "hu", name: "Hungarian" },
        { id: "hy", name: "Armenian" },
        { id: "id", name: "Indonesian" },
        { id: "ig", name: "Igbo" },
        { id: "ilo", name: "Iloko" },
        { id: "is", name: "Icelandic" },
        { id: "it", name: "Italian" },
        { id: "ja", name: "Japanese" },
        { id: "jv", name: "Javanese" },
        { id: "ka", name: "Georgian" },
        { id: "kk", name: "Kazakh" },
        { id: "km", name: "Central Khmer" },
        { id: "kn", name: "Kannada" },
        { id: "ko", name: "Korean" },
        { id: "lb", name: "Luxembourgish; Letzeburgesch" },
        { id: "lg", name: "Ganda" },
        { id: "ln", name: "Lingala" },
        { id: "lo", name: "Lao" },
        { id: "lt", name: "Lithuanian" },
        { id: "lv", name: "Latvian" },
        { id: "mg", name: "Malagasy" },
        { id: "mk", name: "Macedonian" },
        { id: "ml", name: "Malayalam" },
        { id: "mn", name: "Mongolian" },
        { id: "mr", name: "Marathi" },
        { id: "ms", name: "Malay" },
        { id: "my", name: "Burmese" },
        { id: "ne", name: "Nepali" },
        { id: "nl", name: "Dutch; Flemish" },
        { id: "no", name: "Norwegian" },
        { id: "ns", name: "Northern Sotho" },
        { id: "oc", name: "Occitan (post 1500)" },
        { id: "or", name: "Oriya" },
        { id: "pa", name: "Panjabi; Punjabi" },
        { id: "pl", name: "Polish" },
        { id: "ps", name: "Pushto; Pashto" },
        { id: "pt", name: "Portuguese" },
        { id: "ro", name: "Romanian; Moldavian; Moldovan" },
        { id: "ru", name: "Russian" },
        { id: "sd", name: "Sindhi" },
        { id: "si", name: "Sinhala; Sinhalese" },
        { id: "sk", name: "Slovak" },
        { id: "sl", name: "Slovenian" },
        { id: "so", name: "Somali" },
        { id: "sq", name: "Albanian" },
        { id: "sr", name: "Serbian" },
        { id: "ss", name: "Swati" },
        { id: "su", name: "Sundanese" },
        { id: "sv", name: "Swedish" },
        { id: "sw", name: "Swahili" },
        { id: "ta", name: "Tamil" },
        { id: "th", name: "Thai" },
        { id: "tl", name: "Tagalog" },
        { id: "tn", name: "Tswana" },
        { id: "tr", name: "Turkish" },
        { id: "uk", name: "Ukrainian" },
        { id: "ur", name: "Urdu" },
        { id: "uz", name: "Uzbek" },
        { id: "vi", name: "Vietnamese" },
        { id: "wo", name: "Wolof" },
        { id: "xh", name: "Xhosa" },
        { id: "yi", name: "Yiddish" },
        { id: "yo", name: "Yoruba" },
        { id: "zh", name: "Chinese" },
        { id: "zu", name: "Zulu" }
      ]
    end

    # For translating the translation controls into the users locale. Don't translate if it's english
    def translated_languages(user)
      # For translating into the target locale.
      return languages if user.locale.nil?

      locale = trim_locale(user.locale)
      language_cache_key = ["translated_languages", locale].cache_key

      # The controls are in English, don't translate anything
      if locale == "en"
        return languages
      end

      # Check if Redis is present. If yes, then we try to read the key from Redis
      if Canvas.redis_enabled?
        # Try to read the key
        cached_languages = Canvas.redis.get(language_cache_key)
        unless cached_languages.nil?
          return JSON.parse(cached_languages)
        end
      end

      # Translate our language controls
      translated = []
      languages.each do |language|
        language[:name] = create(src_lang: "en", tgt_lang: locale, text: language[:name])
        translated << language
      end

      # Cache the translation for new loads
      if Canvas.redis_enabled?
        Rails.logger.info "Caching supported language translation: #{locale}}}}"
        Canvas.redis.set(language_cache_key, translated.to_json)
      end

      translated
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

    private

    def trim_locale(locale)
      locale[0..1]
    end
  end
end
