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
      VALID_SCOPES = %w[row col rowgroup colgroup].freeze

      def self.test(elem)
        return nil if elem.tag_name.downcase != "th"

        I18n.t("Table header shall have a valid scope associated with it.") unless elem.attribute?("scope") && VALID_SCOPES.include?(elem["scope"])
      end

      def self.display_name
        I18n.t("Table header scope")
      end

      def self.message
        I18n.t("Table header cells should have the scope attribute correctly set to a valid scope value.")
      end

      def self.why
        I18n.t(
          "The scope attribute specifies whether a table header cell applies to a column, row, or group of columns or rows. " \
          "Without this attribute, screen readers may not correctly associate header cells with data cells, " \
          "making tables difficult to navigate and understand."
        )
      end

      # TODO: define undo text
      def self.form(_elem)
        Accessibility::Forms::RadioInputGroupField.new(
          label: I18n.t("Set header scope"),
          undo_text: I18n.t("Table header scope fixed"),
          value: I18n.t("Row"),
          options: [I18n.t("Row"), I18n.t("Column"), I18n.t("Row group"), I18n.t("Column group")]
        )
      end

      def self.fix!(elem, value)
        scope_lookup_table = {
          I18n.t("Row") => "row",
          I18n.t("Column") => "column",
          I18n.t("Row group") => "rowgroup",
          I18n.t("Column group") => "colgroup"
        }
        scope = scope_lookup_table[value]
        if scope
          return nil if elem["scope"] == scope

          elem["scope"] = scope
        else
          raise StandardError, "Invalid scope value. Valid options are: #{VALID_SCOPES.join(", ")}." unless VALID_SCOPES.include?(value)
        end
        elem
      end
    end
  end
end
