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
    class TableCaptionRule < Accessibility::Rule
      self.id = "table-caption"
      self.link = "https://www.w3.org/TR/WCAG20-TECHS/H39.html"

      # Accessibility::Rule methods

      def test(elem)
        return nil if elem.tag_name.downcase != "table"

        caption = elem.query_selector("caption")

        I18n.t("Table caption should be present.") if !caption || caption.text.gsub(/\s/, "") == ""
      end

      def form(_elem)
        Accessibility::Forms::TextInputField.new(
          label: I18n.t("Table caption"),
          undo_text: I18n.t("Caption added"),
          value: "",
          action: I18n.t("Add caption"),
          can_generate_fix: true,
          generate_button_label: I18n.t("Generate")
        )
      end

      def fix!(elem, value)
        raise StandardError, "Caption cannot be empty." if value.blank?

        caption = elem.at_css("caption")
        unless caption
          caption = elem.document.create_element("caption")
          TableCaptionRuleHelper.prepend(elem, caption)
        end
        caption.content = value
        { changed: elem }
      end

      def display_name
        I18n.t("Missing table caption")
      end

      def message
        I18n.t("Tables should include a caption describing the contents of the table.")
      end

      def why
        I18n.t("Tables should have a table caption, a title for the table to help learners understand what the table is about.")
      end
    end
  end
end
