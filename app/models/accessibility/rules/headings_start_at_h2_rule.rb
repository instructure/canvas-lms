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
        I18n.t("Document shall not contain a H1 element.") if elem.tag_name == "h1"
      end

      def self.display_name
        I18n.t("Headings start at H2")
      end

      def self.message
        I18n.t("Headings should start at level 2 (h2).")
      end

      def self.why
        I18n.t(
          "In most content areas of Canvas, the page title is already an h1. " \
          "Using h1 in your content creates an incorrect document structure and " \
          "makes navigation confusing for screen reader users."
        )
      end

      def self.link_text
        I18n.t("Learn more about proper heading structure")
      end

      def self.form(_elem)
        Accessibility::Forms::RadioInputGroupField.new(
          label: I18n.t("How would you like to proceed?"),
          value: I18n.t("Change only this heading level"),
          options: [
            I18n.t("Change only this heading level"),
            I18n.t("Remove heading style")
          ]
        )
      end

      def self.fix!(elem, value)
        case value
        when I18n.t("Change only this heading level")
          elem.name = "h2"
        when I18n.t("Remove heading style")
          elem.name = "p"
        else
          raise ArgumentError, "Invalid value for form: #{value}"
        end
        elem
      end
    end
  end
end
