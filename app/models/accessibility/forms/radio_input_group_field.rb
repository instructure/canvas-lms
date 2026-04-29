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
    class RadioInputGroupField < FormField
      attr_accessor :options, :action

      # @param label [String] Human-readable label displayed to the user
      # @param options [Array<String>] Array of options for the radio input group
      # @param value [String] Optional default value for the radio input group
      # @param action [String] Optional default value for the fix button
      def initialize(label:,
                     undo_text:,
                     options:,
                     value: nil,
                     action: nil)
        super(
          label:,
          undo_text:
        )
        @options = options
        @value = value
        @action = action
      end

      def field_type
        "radio_input_group"
      end

      def to_h
        super.merge({
          options: @options,
          value: @value,
          action: @action
        }.compact)
      end
    end
  end
end
