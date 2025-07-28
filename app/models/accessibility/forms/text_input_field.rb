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
    class TextInputField < FormField
      attr_accessor :value, :placeholder, :action

      # @param label [String] Human-readable label displayed to the user
      # @param placeholder [String] Optional placeholder text for text fields
      # @param value [String] Optional default value for the text field
      # @param action [String] Optional action text for submit button
      def initialize(label:,
                     undo_text:,
                     value:,
                     placeholder: nil,
                     action: nil)
        super(
          label:,
          undo_text:,
        )
        @value = value
        @placeholder = placeholder
        @action = action
      end

      def field_type
        "textinput"
      end

      def to_h
        super.merge({
          value: @value,
          placeholder: @placeholder,
          action: @action
        }.compact)
      end
    end
  end
end
