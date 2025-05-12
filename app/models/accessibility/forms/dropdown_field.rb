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
    class DropdownField < FormField
      attr_accessor :options

      # @param label [String] Human-readable label displayed to the user
      # @param options [Array<String>] Array of options for the dropdown
      # @param value [String] Optional default value for the dropdown
      # @param dom_path [String] Optional DOM path for the element to update
      # @param original_content [String] Optional original HTML content
      # @param updated_content [String] Optional updated HTML content
      def initialize(label:,
                     options:,
                     value:)
        super(
          label:
        )
        @options = options
        @value = value
      end

      def field_type
        "dropdown"
      end

      def to_h
        super.merge({
          options: @options,
          value: @value
        }.compact)
      end
    end
  end
end
