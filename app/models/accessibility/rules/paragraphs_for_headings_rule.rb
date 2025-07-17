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
      self.id = "paragraphs-for-headings"
      self.link = "https://www.w3.org/TR/WCAG20-TECHS/G141.html"

      MAX_HEADING_LENGTH = 120

      IS_HEADING = {
        "h1" => true,
        "h2" => true,
        "h3" => true,
        "h4" => true,
        "h5" => true,
        "h6" => true
      }.freeze

      def self.test(elem)
        return nil unless IS_HEADING[elem.tag_name.downcase]

        if elem.text_content.length > MAX_HEADING_LENGTH
          I18n.t("Heading shall be shorter than %{value}.", { value: MAX_HEADING_LENGTH })
        end
      end

      def self.display_name
        I18n.t("Heading is too long")
      end

      def self.message
        I18n.t("This heading is very long. Is it meant to be a paragraph?")
      end

      def self.why
        I18n.t(
          "Sighted users scan web pages by identifying headings. Similarly, screen reader users rely on headings" \
          "to quickly understand and navigate your content. If a heading is too long, it can be confusing to scan," \
          "harder to read aloud by assistive technology, and less effective for outlining your page. Keep headings" \
          "short, specific, and meaningful, not full sentences or paragraphs."
        )
      end

      def self.form(_elem)
        Accessibility::Forms::Button.new(
          label: I18n.t("Change to paragraph"),
          undo_text: I18n.t("Formatted as paragraph"),
          value: "false"
        )
      end

      def self.fix!(elem, value)
        return nil unless value == "true"

        elem.name = "p"
        elem
      end
    end
  end
end
