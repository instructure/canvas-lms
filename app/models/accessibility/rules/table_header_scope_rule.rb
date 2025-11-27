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
      VALID_SCOPES = %w[row col rowgroup colgroup].freeze

      SCOPE_OPTIONS = [
        { label: -> { I18n.t("The column it's in") }, value: "col" },
        { label: -> { I18n.t("The row it's in") }, value: "row" },
        { label: -> { I18n.t("The column group") }, value: "colgroup" },
        { label: -> { I18n.t("The row group") }, value: "rowgroup" },
      ].freeze

      self.id = "table-header-scope"
      self.link = "https://www.w3.org/TR/WCAG20-TECHS/H63.html"

      # Accessibility::Rule methods

      def test(elem)
        return nil if elem.tag_name.downcase != "th"

        I18n.t("Table header shall have a valid scope associated with it.") unless elem.attribute?("scope") && VALID_SCOPES.include?(elem["scope"])
      end

      def form(_elem)
        options = SCOPE_OPTIONS.map { |opt| opt[:label].call }

        Accessibility::Forms::RadioInputGroupField.new(
          label: I18n.t("Which part of the table does this heading apply to?"),
          undo_text: I18n.t("Heading scope is now set up."),
          value: options.first,
          options:,
          action: I18n.t("Set heading scope")
        )
      end

      def fix!(elem, value)
        scope_lookup_table = SCOPE_OPTIONS.to_h { |opt| [opt[:label].call, opt[:value]] }
        scope = scope_lookup_table[value]
        if scope
          return nil if elem["scope"] == scope

          elem["scope"] = scope
        else
          raise StandardError, "Invalid scope value. Valid options are: #{VALID_SCOPES.join(", ")}." unless VALID_SCOPES.include?(value)
        end

        [elem, table_preview(elem)]
      end

      def display_name
        I18n.t("Table header set up incorrectly")
      end

      def message
        I18n.t("Table headers aren't set up correctly for screen readers to know which headers apply to which cells.")
      end

      def why
        I18n.t(
          "This table header doesn't have scope set up. " \
          "Scope tells screen readers which part of the table a heading applies to."
        )
      end

      def issue_preview(elem)
        table = elem.ancestors("table").first
        return elem.to_html unless table

        table_clone = table.dup
        target_th_index = table.css("th").index(elem)

        if target_th_index && (th_to_highlight = table_clone.css("th")[target_th_index])
          existing_style = (th_to_highlight["style"] || "").strip
          outline_style = "outline: 3px solid #000000 !important; outline-offset: -3px !important;"

          th_to_highlight["style"] = if existing_style.empty?
                                       outline_style
                                     elsif existing_style.end_with?(";")
                                       "#{existing_style} #{outline_style}"
                                     else
                                       "#{existing_style}; #{outline_style}"
                                     end
        end

        table_clone.to_html
      end

      private

      def table_preview(elem)
        table = elem.ancestors("table").first
        return elem.to_html unless table

        table.to_html
      end
    end
  end
end
