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
    class ColorPickerField < FormField
      attr_accessor :default_color

      # @param label [String] Human-readable label displayed to the user
      # @param value [String] Optional default color value
      def initialize(label:,
                     input_label:,
                     title_label:,
                     undo_text:,
                     background_color:,
                     value:,
                     contrast_ratio:,
                     action:,
                     options: {})
        super(
          label:,
          undo_text:
        )
        @input_label = input_label
        @title_label = title_label
        @options = options
        @background_color = background_color
        @value = value
        @action = action
        @contrast_ratio = contrast_ratio
      end

      def field_type
        "colorpicker"
      end

      def to_h
        super.merge({ options: @options, input_label: @input_label, title_label: @title_label, background_color: @background_color, value: @value, contrast_ratio: @contrast_ratio, action: @action }.compact)
      end
    end
  end
end
