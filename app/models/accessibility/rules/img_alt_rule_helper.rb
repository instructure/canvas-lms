# frozen_string_literal: true

#
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

module Accessibility
  module Rules
    class ImgAltRuleHelper
      DEFAULT_REPEAT_COUNT = 3
      MAX_LENGTH = 200
      IMAGE_FILENAME_PATTERN = /[^\s]+(.*?)\.(jpg|jpeg|png|gif|svg|bmp|webp)$/i

      def self.generate_alt_text(image_url, config_name: "alt_text_generate", try_counter: DEFAULT_REPEAT_COUNT)
        return nil if image_url.blank?

        begin
          url = URI.parse(image_url)
          http_response = Net::HTTP.get_response(url)
          unless http_response.is_a?(Net::HTTPSuccess)
            raise "Content download failed with status: #{http_response.code}"
          end

          image_data = http_response.body
          base64_image = Base64.strict_encode64(image_data)
          llm_config = LLMConfigs.config_for(config_name)
          unless llm_config
            raise "LLM configuration not found for: #{config_name}"
          end

          prompt, = llm_config.generate_prompt_and_options(substitutions: {})

          multimodal_content = [
            { type: "text", text: prompt },
            {
              type: "image",
              source: {
                type: "base64",
                media_type: "image/png",
                data: base64_image
              }
            }
          ]

          response = InstLLMHelper.client(llm_config.model_id).chat(
            [{ role: "user", content: multimodal_content }]
          )
          alt_text = response.message[:content]

          if alt_text_valid?(alt_text)
            alt_text
          elsif try_counter > 0
            Rails.logger.warn("Generated alt text is invalid, retrying... (#{try_counter} attempts left)")
            generate_alt_text(image_url, config_name:, try_counter: try_counter - 1) if try_counter > 0
          else
            Rails.logger.error("Failed to generate valid alt text after multiple attempts. Tried #{DEFAULT_REPEAT_COUNT} times.")
            raise "Failed to generate valid alt text after multiple attempts."
          end
        rescue => e
          Rails.logger.error("Error generating alt text: #{e.message}")
          raise
        end
      end

      def self.alt_text_valid?(alt_text)
        return false if alt_text.blank? || alt_text.length > MAX_LENGTH

        true
      end

      def self.filename_like?(text)
        return false if text.blank?

        IMAGE_FILENAME_PATTERN.match?(text)
      end

      def self.adjust_img_style(elem)
        fixed_elem = elem.dup
        fixed_elem["style"] = "max-width: 100%; max-height: 13rem; object-fit: contain;"
        fixed_elem.to_html
      end

      def self.validation_error_missing
        I18n.t("Alt text is required.")
      end

      def self.validation_error_filename
        I18n.t("Alt text can not be a filename.")
      end

      def self.validation_error_too_long
        I18n.t("Keep alt text under %{max_length} characters.", max_length: MAX_LENGTH)
      end

      def self.fix_alt_text!(elem, value)
        if value.blank?
          elem["role"] = "presentation"
          elem["alt"] = ""
          return [elem, adjust_img_style(elem)]
        end

        if filename_like?(value)
          raise StandardError, validation_error_filename
        end

        if value.length > MAX_LENGTH
          raise StandardError, validation_error_too_long
        end

        elem["alt"] = value
        [elem, adjust_img_style(elem)]
      end
    end
  end
end
