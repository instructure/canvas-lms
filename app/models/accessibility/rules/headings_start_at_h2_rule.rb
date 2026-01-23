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
      self.link = "https://www.w3.org/TR/WCAG20-TECHS/G141.html"

      # Accessibility::Rule methods

      def test(elem)
        I18n.t("Document shall not contain a H1 element.") if elem.tag_name == "h1"
      end

      def form(_elem)
        Accessibility::Forms::RadioInputGroupField.new(
          label: I18n.t("How would you like to proceed?"),
          undo_text: I18n.t("Reformatted"),
          value: I18n.t("Change it to Heading 2"),
          action: I18n.t("Reformat"),
          options: [
            I18n.t("Change it to Heading 2"),
            I18n.t("Turn into paragraph")
          ]
        )
      end

      def fix!(elem, value)
        case value
        when I18n.t("Change it to Heading 2")
          elem.name = "h2"
        when I18n.t("Turn into paragraph")
          elem.name = "p"
        else
          raise ArgumentError, "Invalid value for form: #{value}"
        end
        { changed: elem }
      end

      def display_name
        I18n.t("Heading levels should start at level 2")
      end

      def message
        I18n.t(
          "This text is styled as a Heading 1, but there should only be one H1 on a web page — the page title. " \
          "Use Heading 2 or lower (H2, H3, etc.) for your content headings instead."
        )
      end

      def why
        [
          I18n.t(
            "Sighted users scan web pages quickly by looking for large or bolded headings. " \
            "Similarly, screen reader users rely on properly structured headings to scan the content and jump directly to key sections. " \
            "Using correct heading levels in a logical order (like H2, H3, etc.) ensures your course is clear, organized, and accessible to everyone."
          ),
          I18n.t(
            "Each page on Canvas already has a main title (H1), so your content should start with an H2 to keep the structure clear."
          )
        ]
      end
    end
  end
end
