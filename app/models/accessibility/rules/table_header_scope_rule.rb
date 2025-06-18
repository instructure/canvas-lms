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
    class TableHeaderScopeRule < Accessibility::Rule
      self.id = "table-header-scope"
      self.link = "https://www.w3.org/TR/WCAG20-TECHS/H63.html"

      def self.test(elem)
        return true if elem.tag_name.downcase != "th"

        elem.attribute?("scope")
      end

      def self.message
        "Table header cells should have the scope attribute."
      end

      def self.why
        "The scope attribute specifies whether a table header cell applies to a column, row, or group of columns or rows. " \
          "Without this attribute, screen readers may not correctly associate header cells with data cells, " \
          "making tables difficult to navigate and understand."
      end

      def self.link_text
        "Learn more about table header scope attributes"
      end

      def self.form(_elem)
        Accessibility::Forms::DropdownField.new(
          label: "Set header scope",
          value: "None",
          options: ["None", "Row", "Column", "Row group", "Column group"]
        )
      end

      def self.fix(elem, value)
        value_symbol = value.to_sym

        scope_lookup_table = {
          Row: "row",
          Column: "column",
          "Row group": "rowgroup",
          "Column group": "colgroup"
        }

        if value_symbol == :None
          elem.remove_attribute("scope")
        elsif scope_lookup_table.key?(value_symbol)
          elem["scope"] = scope_lookup_table[value_symbol]
        end

        elem
      end
    end
  end
end
