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
  class FormField
    attr_accessor :label, :data_key, :checkbox, :options, :placeholder
    attr_reader :disabled_if_proc

    # @param label [String] Human-readable label displayed to the user
    # @param data_key [String] Key to access data in the rule's data object
    # @param checkbox [Boolean] Optional - if true, renders as a checkbox
    # @param options [Array<Array<String, String>>] Optional array of options for select fields [value, label]
    # @param disabled_if [Proc] Optional proc to determine if field should be disabled
    # @param placeholder [String] Optional placeholder text for text fields
    def initialize(label:, data_key:, checkbox: false, options: nil, disabled_if: nil, placeholder: nil)
      @label = label
      @data_key = data_key
      @checkbox = checkbox
      @options = options
      @disabled_if_proc = disabled_if
      @placeholder = placeholder
    end

    # Determines if the field should be disabled based on provided data
    # @param data [Hash] The data to check against
    # @return [Boolean] True if the field should be disabled, false otherwise
    def disabled?(data)
      return false unless @disabled_if_proc

      @disabled_if_proc.call(data)
    end

    def to_json(*options)
      to_h.to_json(*options)
    end

    def to_h
      hash = {
        label: @label,
        data_key: @data_key,
        has_disabled_condition: !@disabled_if_proc.nil?
      }
      hash[:checkbox] = @checkbox if @checkbox
      hash[:options] = @options if @options
      hash[:placeholder] = @placeholder if @placeholder
      hash
    end
  end
end
