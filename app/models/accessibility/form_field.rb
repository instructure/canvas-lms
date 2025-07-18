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
    attr_accessor :label, :undo_text, :can_generate_fix

    # @param label [String] Human-readable label displayed to the user
    # @param undo_text [String] Text for the undo action
    # @param can_generate_fix [Boolean] Indicates if the field can generate a fix
    def initialize(label:, undo_text:, can_generate_fix: false)
      @label = label
      @undo_text = undo_text
      @can_generate_fix = can_generate_fix
    end

    def to_json(*options)
      to_h.to_json(*options)
    end

    def to_h
      {
        type: field_type,
        undo_text:,
        label:,
        can_generate_fix:
      }.compact
    end

    def field_type
      raise NotImplementedError, "Subclasses must implement field_type"
    end
  end
end
