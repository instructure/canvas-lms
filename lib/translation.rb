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
        result = CLD.detect_language(text)[:code][0..2]
        if result == "un" # Unknown language code.
          logger.warn("Could not detect language from src text, defaulting to English")
          src_lang = "en"
        else
          src_lang = result
        end
      end

      # If target lang was nil, then user must be set. Try to get locale from the user.
      if tgt_lang.nil?
        tgt_lang = if user.locale.nil?
                     # Go ahead and use english as the target language. It is the system default for Canvas.
                     "en"
                   else
                     user.locale[0..2]
                   end
      end

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
        { id: "en", name: "English" },
        { id: "ga", name: "Irish" },
        { id: "ja", name: "Japanese" },
        { id: "de", name: "German" },
        { id: "hu", name: "Hungarian" },
        { id: "es", name: "Spanish" },
        { id: "zh", name: "Chinese" }
      ]
    end

    # For translating the translation controls into the users locale. Don't translate if it's english
    def translated_languages(user)
      # For translating into the target locale.
      return languages if user.locale.nil?

      locale = user.locale[0..2]
      # Don't translate unless the browser locale is different for the current user.
      if locale == "en"
        return languages
      end

      translated = []
      languages.each do |language|
        language[:name] = create(src_lang: "en", tgt_lang: locale, text: language[:name])
        translated << language
      end

      translated
    end

    def language_matches_user_locale?(user, text)
      locale = if user.locale.nil?
                 "en"
               else
                 user.locale[0..2]
               end
      result = CLD.detect_language(text)[:code][0..2]
      result == locale
    end

    def translate_message(text:, user:)
      translated_text = []
      src_lang = CLD.detect_language(text)[:code][0..2]
      tgt_lang = if user.locale.nil?
                   "en"
                 else
                   user.locale[0..2]
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
  end
end
