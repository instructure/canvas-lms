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
  module Forms
    class TextInputWithCheckboxField < FormField
      attr_accessor :checkbox_label,
                    :input_label,
                    :checkbox_subtext,
                    :input_description,
                    :input_max_length,
                    :checked,
                    :value

      # @param checkbox_label [String] Human-readable label for the checkbox
      # @param checkbox_subtext [String] Optional subtext for the checkbox
      # @param input_label [String] Human-readable label for the input field
      # @param input_description [String] Optional description for the input field
      # @param input_max_length [Integer] Optional maximum length for the input field
      # @param value [String] Optional default value for the input field
      def initialize(checkbox_label:,
                     input_label:,
                     undo_text:,
                     can_generate_fix:,
                     generate_button_label:,
                     checkbox_subtext: nil,
                     input_description: nil,
                     input_max_length: nil,
                     value: nil)
        super(label: input_label, undo_text:, can_generate_fix:)
        @checkbox_label = checkbox_label
        @checkbox_subtext = checkbox_subtext
        @input_description = input_description
        @input_max_length = input_max_length
        @value = value
        @generate_button_label = generate_button_label
      end

      def field_type
        "checkbox_text_input"
      end

      def to_h
        super.merge({
          checkbox_label: @checkbox_label,
          checkbox_subtext: @checkbox_subtext,
          input_description: @input_description,
          input_max_length: @input_max_length,
          value: @value,
          generate_button_label: @generate_button_label,
        }.compact)
      end
    end
  end
end
