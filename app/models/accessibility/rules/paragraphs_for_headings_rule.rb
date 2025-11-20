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
    class ParagraphsForHeadingsRule < Accessibility::Rule
      MAX_HEADING_LENGTH = 120

      self.id = "paragraphs-for-headings"
      self.link = nil

      # Accessibility::Rule methods

      def test(elem)
        return nil unless self.class.h_tag?(elem)

        if elem.text_content.length > MAX_HEADING_LENGTH
          I18n.t("Heading shall be shorter than %{value}.", { value: MAX_HEADING_LENGTH })
        end
      end

      def form(_elem)
        Accessibility::Forms::Button.new(
          label: I18n.t("Change to paragraph"),
          undo_text: I18n.t("Formatted as paragraph"),
          value: "false"
        )
      end

      def self.h_tag?(elem)
        elem&.tag_name&.downcase&.match?(/^h[1-6]$/)
      end

      def fix!(elem, value)
        return nil unless value == "true"

        elem.name = "p"
        elem
      end

      def display_name
        I18n.t("Heading is too long")
      end

      def message
        I18n.t("This heading is very long. Is it meant to be a paragraph?")
      end

      def why
        [I18n.t(
          "Sighted users scan web pages by identifying headings. Similarly, screen reader users rely on headings" \
          "to quickly understand and navigate your content. If a heading is too long, it can be confusing to scan," \
          "harder to read aloud by assistive technology, and less effective for outlining your page."
        ),
         I18n.t("Keep headings short, specific, and meaningful, not full sentences or paragraphs.")]
      end
    end
  end
end
