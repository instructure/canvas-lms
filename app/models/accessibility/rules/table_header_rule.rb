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
    class TableHeaderRule < Accessibility::Rule
      self.id = "table-header"
      self.link = "https://www.w3.org/TR/WCAG20-TECHS/H51.html"

      def self.test(elem)
        return nil if elem.tag_name != "table"

        I18n.t("Table shall have a header.") if elem.query_selector("th").nil?
      end

      def self.display_name
        I18n.t("Table headers aren’t set up")
      end

      def self.message
        I18n.t("Tables should include a caption describing the contents of the table.")
      end

      def self.why
        I18n.t(
          "Tables without headers are difficult for screen reader users to navigate and understand. " \
          "Headers provide context for the data and allow screen readers to associate data cells with their headers."
        )
      end

      def self.link_text
        I18n.t("Learn more about table headers")
      end

      def self.form(_elem)
        Accessibility::Forms::RadioInputGroupField.new(
          label: I18n.t("Which part of the table should contain the headings?"),
          value: I18n.t("The top row"),
          options: [
            I18n.t("The top row"),
            I18n.t("The left column"),
            I18n.t("Both")
          ]
        )
      end

      def self.fix!(elem, value)
        elem.query_selector_all("th").each do |th|
          th.name = "td"
        end

        if [I18n.t("The top row"), I18n.t("Both")].include?(value)
          first_row = elem.query_selector("tr")
          first_row&.query_selector_all("td")&.each do |td|
            td.name = "th"
            td["scope"] = "col"
          end
        end

        if [I18n.t("The left column"), I18n.t("Both")].include?(value)
          elem.query_selector_all("tr").each_with_index do |row, index|
            next if index == 0 # Skip the first row

            first_cell = row.query_selector("td")
            if first_cell
              first_cell.name = "th"
              first_cell["scope"] = "row"
            end
          end
        end

        elem
      end
    end
  end
end
