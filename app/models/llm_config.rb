# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

class LLMConfig
  attr_reader :name, :model_id, :rate_limit, :template, :options

  def initialize(name:, model_id:, rate_limit: nil, template: nil, options: nil)
    @name = name
    @model_id = model_id
    @rate_limit = rate_limit&.transform_keys(&:to_sym)
    @template = template
    @options = options || {}
    validate!
  end

  def generate_prompt_and_options(substitutions:)
    new_template = template.dup

    substitutions.each do |placeholder_prefix, sub_value|
      new_template.gsub!("<#{placeholder_prefix}_PLACEHOLDER>", sub_value.to_s)
    end

    if (remaining_placeholder = new_template.match(/<\w+_PLACEHOLDER>/))
      raise ArgumentError, "Template still contains placeholder: #{remaining_placeholder[0]}"
    end

    new_options = options.deep_dup

    new_options.each do |key, value|
      substitutions.each do |placeholder_prefix, sub_value|
        new_options[key] = value.gsub("<#{placeholder_prefix}_PLACEHOLDER>", sub_value.to_s) if value.is_a?(String)
      end
    end

    new_options.each_value do |value|
      if value.is_a?(String) && (remaining_placeholder = value.match(/<\w+_PLACEHOLDER>/))
        raise ArgumentError, "Options still contain placeholder: #{remaining_placeholder[0]}"
      end
    end

    [new_template, new_options]
  end

  private

  def validate!
    raise ArgumentError, "Name must be a string" unless @name.is_a?(String)
    raise ArgumentError, "Model ID must be a string" unless @model_id.is_a?(String)
    raise ArgumentError, "Rate limit must be either nil, or hash with :limit and :period keys" unless @rate_limit.nil? || (@rate_limit.is_a?(Hash) && @rate_limit.keys == %i[limit period])
    raise ArgumentError, "Template must be a string" unless @template.is_a?(String)
    raise ArgumentError, "Options must be a hash" unless @options.is_a?(Hash)
  end
end
