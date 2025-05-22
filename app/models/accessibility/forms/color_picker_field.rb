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
      # @param dom_path [String] Optional DOM path for the element to update
      # @param original_content [String] Optional original HTML content
      # @param updated_content [String] Optional updated HTML content
      def initialize(label:,
                     value: nil)
        super(
          label:
        )
        @value = value
      end

      def field_type
        "colorpicker"
      end

      def to_h
        super.merge({ value: @value }.compact)
      end
    end
  end
end
