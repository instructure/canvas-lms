
require "i18nliner/processors/abstract_processor"
require "i18nliner/scope"
require 'i18nliner/call_helpers'
require "yaml"

module I18nliner
  module Processors
    class FeatureFlagYamlProcessor < AbstractProcessor
      default_pattern 'config/feature_flags/*.yml'

      def check_file(file)
        @file_count += 1
        definitions = YAML.load_file(file)
        definitions.each do |name, definition|
          definition.deep_symbolize_keys!
          [:display_name, :description].each do |field|
            @translation_count += 1
            @translations.line = name.to_s
            value = definition[field]
            if value.is_a?(String)
              key = I18nliner::CallHelpers.infer_key(value)
              @translations[key] = value
            elsif value.is_a?(Hash)
              value.delete(:wrapper)
              key = value.keys[0]
              @translations[key.to_s] = value[key]
            end
          end
        end
      end
    end
  end
end

I18nliner::Processors.register(I18nliner::Processors::FeatureFlagYamlProcessor)
