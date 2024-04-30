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

class LlmConfig
  attr_reader :name, :model_id, :template, :options

  def initialize(name:, model_id:, template: nil, options: nil)
    @name = name
    @model_id = model_id
    @template = template
    @options = options || {}
    validate!
  end

  def generate_prompt(dynamic_content:)
    return dynamic_content if template.nil?

    template.gsub("<PLACEHOLDER>", dynamic_content)
  end

  private

  def validate!
    raise ArgumentError, "Name must be a string" unless @name.is_a?(String)
    raise ArgumentError, "Model ID must be a string" unless @model_id.is_a?(String)
    raise ArgumentError, "Template must be a string or nil" unless @template.nil? || @template.is_a?(String)
    raise ArgumentError, "Options must be a hash" unless @options.is_a?(Hash)
  end
end
