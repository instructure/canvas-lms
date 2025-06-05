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
  module Rules
    class HeadingsStartAtH2Rule < Accessibility::Rule
      self.id = "headings-start-at-h2"
      self.link = "https://www.w3.org/WAI/tutorials/page-structure/headings/"

      def self.test(elem)
        elem.tag_name != "h1"
      end

      def self.message
        "Headings should start at level 2 (h2)."
      end

      def self.why
        "In most content areas of Canvas, the page title is already an h1. " \
          "Using h1 in your content creates an incorrect document structure and " \
          "makes navigation confusing for screen reader users."
      end

      def self.link_text
        "Learn more about proper heading structure"
      end

      def self.form(_elem)
        Accessibility::Forms::DropdownField.new(
          label: "Choose action",
          value: "Leave as is",
          options: ["Leave as is", "Change only this headings level", "Remove heading style"]
        )
      end

      def self.fix(elem, value)
        case value
        when "Leave as is"
          # Do nothing
        when "Change only this headings level"
          elem.name = "h2"
        when "Remove heading style"
          elem.name = "p"
        else
          raise ArgumentError, "Invalid value for form: #{value}"
        end
      end
    end
  end
end
