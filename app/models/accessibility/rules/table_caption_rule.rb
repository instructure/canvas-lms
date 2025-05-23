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

      def self.test(elem)
        return true if elem.tag_name.downcase != "table"

        caption = elem.query_selector("caption")
        !!caption && caption.text_content.gsub(/\s/, "") != ""
      end

      def self.message
        I18n.t("Tables should include a caption describing the contents of the table.")
      end

      def self.why
        I18n.t("Screen readers cannot interpret tables without the proper structure. Table captions describe the context and general understanding of the table.")
      end

      def self.link_text
        I18n.t("Learn more about using captions with tables")
      end

      def self.prepend(parent, child)
        if parent.first_element_child
          parent.first_element_child.add_previous_sibling(child)
        else
          parent.add_child(child)
        end
      end

      def self.form(_elem)
        Accessibility::Forms::TextInputField.new(
          label: "Change table caption",
          value: ""
        )
      end

      def self.fix(elem, value)
        caption = elem.at_css("caption")
        unless caption
          caption = elem.document.create_element("caption")
          prepend(elem, caption)
        end
        caption.content = value
        elem
      end
    end
  end
end
