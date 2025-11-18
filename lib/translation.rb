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
require "pragmatic_segmenter"
require "nokogiri"

module Translation
  class TranslationError < StandardError
  end

  class SameLanguageTranslationError < TranslationError
  end

  class TextTooLongError < TranslationError
  end

  class UnsupportedLanguageError < TranslationError
  end

  class ValidationError < TranslationError
  end

  class CedarLimitReachedError < TranslationError
  end

  module TranslationType
    AWS_TRANSLATE = :aws_translate
    SAGEMAKER = :sagemaker
    CEDAR = :cedar
    DISABLED = nil
  end

  module TranslationSlugs
    DEFAULT = "content-translation"
    INBOX = "inbox"
    DISCUSSION = "discussion"
    TYPES = TranslationSlugs.constants.map { |c| TranslationSlugs.const_get(c) }
  end

  class << self
    # The languages are imported from https://docs.aws.amazon.com/translate/latest/dg/what-is-languages.html
    # TODO: Currently we don't support dialects(trim_locale function) because the currently implemented
    # language detector supports dialects that the translator does not. Probably we should migrate to the
    # automatic language detection that AWS translate provides but it needs additional discovery since
    # it incurs cost and not necessarily available in all the regions.
    # List of languages supported by our current detector: https://github.com/google/cld3
    def languages(flags)
      case current_translation_provider_type(flags)
      when TranslationType::AWS_TRANSLATE
        AwsTranslator.languages
      when TranslationType::SAGEMAKER
        SagemakerTranslator.languages
      when TranslationType::CEDAR
        CedarTranslator.languages
      else
        []
      end
    end

    delegate :logger, to: :Rails

    def current_translation_provider_type(flags)
      return nil unless flags.key?(:translation) && flags[:translation]

      return TranslationType::CEDAR if flags[:cedar_translation]
      return TranslationType::AWS_TRANSLATE if flags[:ai_translation_improvements]

      TranslationType::SAGEMAKER
    end

    def translation_client(flags)
      @translation_client ||= begin
        provider_type = current_translation_provider_type(flags)
        case provider_type
        when TranslationType::AWS_TRANSLATE
          AwsTranslator.new
        when TranslationType::SAGEMAKER
          SagemakerTranslator.new
        when TranslationType::CEDAR
          CedarTranslator.new
        else
          nil
        end
      end
    end

    def available?(flags)
      return false unless flags[:translation]

      translation_client(flags)&.available? || false
    end

    def translate_text(text:, tgt_lang:, options: {}, flags: {})
      return nil unless translation_client(flags)&.available?

      unless options[:feature_slug] && TranslationSlugs::TYPES.include?(options[:feature_slug])
        options[:feature_slug] = TranslationSlugs::DEFAULT
      end

      translation_client(flags).translate_text(text:, tgt_lang:, options:)
    end

    def translate_html(html_string:, tgt_lang:, options: {}, flags: {})
      return nil unless translation_client(flags)&.available?

      unless options[:feature_slug] && TranslationSlugs::TYPES.include?(options[:feature_slug])
        options[:feature_slug] = TranslationSlugs::DEFAULT
      end

      translation_client(flags).translate_html(html_string:, tgt_lang:, options:)
    end

    def get_translation_flags(enabled, domain_root_account)
      {
        translation: enabled,
        ai_translation_improvements: domain_root_account.feature_enabled?(:ai_translation_improvements),
        cedar_translation: domain_root_account.feature_enabled?(:cedar_translation),
      }
    end
  end
end
